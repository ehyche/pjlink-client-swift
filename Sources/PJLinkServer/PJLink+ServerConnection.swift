//
//  PJLink+ServerConnection.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/14/26.
//

import ConcurrencyExtras
import Network
import os
import PJLinkCommon

extension PJLink {

    public final class ServerConnection: Sendable {
        public typealias OnTerminated = @Sendable (ServerConnection) -> Void

        private let connection: NetworkConnection<TCP>
        private let state: LockIsolated<PJLink.State>
        private let authConfig: AuthConfig
        private let onTerminated: OnTerminated
        private let authState = LockIsolated<PJLink.ServerAuthState>(.indeterminate)

        public init(
            connection: NetworkConnection<TCP>,
            state: LockIsolated<PJLink.State>,
            authConfig: AuthConfig,
            onTerminated: @escaping OnTerminated
        ) {
            self.connection = connection
            self.state = state
            self.authConfig = authConfig
            self.onTerminated = onTerminated
        }

        public func run() async throws {
            let logger = Logger(cat: .connection)
            connection.onBetterPathUpdate { connection, newValue in
                logger.debug("Connection[\(connection.id)] onBetterPathUpdate: \(newValue)")
            }
            connection.onPathUpdate { connection, newPath in
                logger.debug("Connection[\(connection.id)] onPathUpdate: \(newPath.debugDescription)")
            }
            connection.onViabilityUpdate { connection, newViable in
                logger.debug("Connection[\(connection.id)] onViabilityUpdate: \(newViable)")
            }
            connection.onStateUpdate { connection, state in
                let stateDesc: String
                switch state {
                case .setup: stateDesc = "Setup"
                case .waiting(let error): stateDesc = "Waiting(\(error))"
                case .preparing: stateDesc = "Preparing"
                case .ready: stateDesc = "Ready"
                case .failed(let error): stateDesc = "Failed(\(error))"
                case .cancelled: stateDesc = "Cancelled"
                @unknown default: stateDesc = "Unknown"
                }
                logger.debug("Connection[\(connection.id)] onStateUpdate: \(stateDesc)")
                switch state {
                case .failed:
                    self.onTerminated(self)
                case .cancelled:
                    self.onTerminated(self)
                default:
                    break
                }
            }

            // We need to send the initial auth response
            do {
                let authResponse: PJLink.AuthResponse
                if authConfig.password != nil {
                    // We have a password in the AuthConfig, so we need
                    // to send the initial "PJLINK 1 49834a67" response
                    // with a 4-byte random number.
                    let random4 = try PJLink.Buffer4.random()
                    authResponse = PJLink.AuthResponse.securityLevel1(random4)
                    try await connection.send(authResponse.description.crTerminatedData)
                    authState.setValue(.class1AuthResponseSent(random4))
                } else {
                    // We have no password in the AuthConfig, so authentication is disabled.
                    // We therefore send "PJLINK 0".
                    authResponse = PJLink.AuthResponse.authDisabled
                    try await connection.send(authResponse.description.crTerminatedData)
                    authState.setValue(.disabled)
                }
            } catch {
                logger.error("Connection[\(self.connection.id)] Initial Auth Response Error: \(error)")
                return
            }

            // Loop through, receiving a request and processing it.
            while !connection.state.isFinished {
                let authMessage: AuthMessage
                let request: Message.Request?
                do {
                    (authMessage, request) = try await receiveRequest(on: connection, logger: logger)
                } catch let pjlinkError as PJLink.Error  {
                    // We assume PJLink.Error are parsing errors, and therefore recoverable
                    logger.error("Connection[\(self.connection.id)] Error Receiving Request: \(pjlinkError)")
                    continue
                } catch {
                    // We assume the rest of the errors are socket-related and not recoverable,
                    // so we break out of the loop
                    logger.error("Connection[\(self.connection.id)] Error Receiving Request: \(error)")
                    break
                }

                do {
                    try await processRequest(
                        authState: authState,
                        authMessage: authMessage,
                        authConfig: authConfig,
                        state: state,
                        request: request,
                        connection: connection,
                        logger: logger
                    )
                } catch {
                    logger.error("Connection[\(self.connection.id)] Error Processing Request: \(error)")
                }
            }

            logger.debug("Connection[\(self.connection.id)] run() finished")
        }
    }

    static func receiveRequest(
        on connection: NetworkConnection<TCP>,
        logger: Logger
    ) async throws -> (AuthMessage, Message.Request?) {
        let maxRequestSize = PJLink.maxAuthRequestSize + PJLink.maxRequestSize
        let requestData = try await connection.receive(atMost: maxRequestSize).content
        let requestUTF8 = try requestData.toUTF8String()
        logger.info("Connection[\(connection.id)] RECV: \"\(requestUTF8, privacy: .public)\"")

        // We look for the "%" which marks the beginning of the request.
        var request: Message.Request?
        var authString = requestUTF8
        if let percentIndex = requestUTF8.firstIndex(of: PJLink.identifierCharacter) {
            authString = String(requestUTF8[requestUTF8.startIndex..<percentIndex])
            request = try Message.Request(String(requestUTF8[percentIndex..<requestUTF8.endIndex]))
        }
        let authMessage = try PJLink.AuthMessage(authString)

        return (authMessage, request)
    }

    static func processRequest(
        authState: LockIsolated<PJLink.ServerAuthState>,
        authMessage: AuthMessage,
        authConfig: AuthConfig,
        state: LockIsolated<PJLink.State>,
        request: Message.Request?,
        connection: NetworkConnection<TCP>,
        logger: Logger
    ) async throws {
        if authMessage == .securityLevel {
            // We received a "PJLINK 2" request, so respond with "PJLINK 2 3db2...97eo".
            let projectorRandom16 = try Buffer16.random()
            let authResponse: AuthResponse = .securityLevel2(projectorRandom16)
            try await connection.send(authResponse.description.crTerminatedData)
            logger.info("Connection[\(connection.id)] SEND: \"\(authResponse.description)\"")
            // Update the ServerAuthState
            authState.setValue(.class2AuthResponseSent(projectorRandom16))
        } else if let request {
            // Validate the authentication
            try validateAuthentication(authState: authState.value, authMessage: authMessage, authConfig: authConfig)
            // Generate a response to the request
            let response = try generateResponse(state: state, request: request)
            // Send the response
            try await connection.send(response.description.crTerminatedData)
            logger.info("Connection[\(connection.id)] SEND: \"\(response.description)\"")
            // Update the ServerAuthState
            updateAuthStateOnSuccess(authState: authState)
        }
    }

    static func validateAuthentication(
        authState: PJLink.ServerAuthState,
        authMessage: AuthMessage,
        authConfig: AuthConfig
    ) throws {
        switch (authState, authMessage, authConfig.password) {
        case (.disabled, .none, .none):
            // Authentication is disabled, no auth message was received, and we have no password
            break
        case (.disabled, _, _):
            // Authentication was disabled, but we received an auth message anyway
            throw PJLink.Error.unexpectedAuthMessage(expected: .none, actual: authMessage)
        case let (.class1AuthResponseSent(projectorRandom4), .class1(clientHash), .some(password)),
             let (.class1Authenticated(projectorRandom4), .class1(clientHash), .some(password)):
            // We sent a Class 1 random number, we received a class 1 hash, and we have a password.
            // This is likely a Class 1 client.
            let auth = PJLink.AuthState.level1(projectorRandom: projectorRandom4, password: password)
            if auth.authString != clientHash.data.hexEncodedString {
                throw PJLink.Error.authenticationFailure(expected: auth.authString, actual: clientHash.data.hexEncodedString)
            }
        case (.class1AuthResponseSent, .securityLevel, .some):
            // We sent a Class 1 random number, and we received a security level request ("PJLINK 2").
            // This is likely a class 2 client. When we respond, we will provide a 16-byte random number,
            // but there is no checking we need to do yet.
            break
        case let (.class2AuthResponseSent(projectorRandom16), .class2(clientRandom16, clientHash), .some(password)),
            let (.class2Authenticated(projectorRandom16), .class2(clientRandom16, clientHash), .some(password)):
            // We sent a Class 2 16-byte random number, we receive a Class 2 request,
            // and we have a password. This is likely a Class 2 client.
            let auth = PJLink.AuthState.level2(
                clientRandom: clientRandom16,
                projectorRandom: projectorRandom16,
                password: password
            )
            if auth.hash != clientHash.data.hexEncodedString {
                throw PJLink.Error.authenticationFailure(expected: auth.hash, actual: clientHash.data.hexEncodedString)
            }
        case (.class1Authenticated, .none, .some):
            // We have already authenticted Class 1, so we no longer need to re-authenticate.
            break
        case (.class2Authenticated, .none, .some):
            // We have already authenticated Class 2, so we no longer need to re-authenticate.
            break
        default:
            throw PJLink.Error.unexpectedAuthValidationState(
                state: authState,
                message: authMessage,
                password: authConfig.password
            )
        }
    }

    static func generateResponse(
        state: LockIsolated<PJLink.State>,
        request: Message.Request
    ) throws -> Message.Response {
        switch request {
        case .get(let getRequest):
            .get(getResponse(for: getRequest, state: state.value))
        case .set(let setRequest):
            .set(setResponse(for: setRequest, state: state))
        }
    }

    static func getResponse(
        for getRequest: PJLink.GetRequest,
        state: PJLink.State
    ) -> PJLink.GetResponse {
        switch (getRequest, state) {
        case (.power, _):
            return .success(.power(state.power))
        case (.inputSwitchClass1, .class1(let class1State)):
            return .success(.inputSwitchClass1(class1State.activeInputSwitch))
        case (.inputSwitchClass1, .class2):
            // TODO - handle producing Class 1 inputs from Class 2 inputs
            return .failure(.init(pjLinkClass: .one, command: .inputSwitch, code: .undefinedCommand))
        case (.inputSwitchClass2, .class1):
            // We are emulating a Class 1 projector, so we fail on a Class 2 request
            return .failure(.init(pjLinkClass: .two, command: .inputSwitch, code: .undefinedCommand))
        case (.inputSwitchClass2, .class2(let class2State)):
            return .success(.inputSwitchClass2(class2State.activeInputSwitch))
        case (.avMute, _):
            return .success(.avMute(state.mute))
        case (.errorStatus, _):
            return .success(.errorStatus(state.error))
        case (.lamp, _):
            return .success(.lamp(state.lamps))
        case (.inputListClass1, .class1(let class1State)):
            return .success(.inputListClass1(class1State.inputSwitches))
        case (.inputListClass1, .class2):
            // TODO - handle producing Class 1 inputs from Class 2 inputs
            return .failure(.init(pjLinkClass: .one, command: .inputList, code: .undefinedCommand))
        case (.inputListClass2, .class1):
            return .failure(.init(pjLinkClass: .two, command: .inputList, code: .undefinedCommand))
        case (.inputListClass2, .class2(let class2State)):
            return .success(.inputListClass2(class2State.inputSwitches))
        case (.projectorName, _):
            return .success(.projectorName(state.projectorName))
        case (.manufacturerName, _):
            return .success(.manufacturerName(state.manufacturerName))
        case (.productName, _):
            return .success(.productName(state.productName))
        case (.otherInformation, _):
            return .success(.otherInformation(state.otherInformation))
        case (.projectorClass, _):
            return .success(.projectorClass(state.class))
        case (.serialNumber, .class1):
            // We are emulating a Class 1 projector, so SNUM does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .serialNumber, code: .undefinedCommand))
        case (.serialNumber, .class2(let class2State)):
            return .success(.serialNumber(class2State.serialNumber))
        case (.softwareVersion, .class1):
            // We are emulating a Class 1 projector, so SVER does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .softwareVersion, code: .undefinedCommand))
        case (.softwareVersion, .class2(let class2State)):
            return .success(.softwareVersion(class2State.softwareVersion))
        case (.inputTerminalName, .class1):
            return .failure(.init(pjLinkClass: .one, command: .inputTerminalName, code: .undefinedCommand))
        case (.inputTerminalName(let inputSwitchClass2), .class2(let class2State)):
            if let inputTerminalName = class2State.inputNames[inputSwitchClass2] {
                return .success(.inputTerminalName(inputTerminalName))
            } else {
                return .failure(.init(pjLinkClass: .two, command: .inputTerminalName, code: .outOfParameter))
            }
        case (.inputResolution, .class1):
            // We are emulating a Class 1 projector, so IRES does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .inputResolution, code: .undefinedCommand))
        case (.inputResolution, .class2(let class2State)):
            return .success(.inputResolution(class2State.inputResolution))
        case (.recommendedResolution, .class1):
            // We are emulating a Class 1 projector, so RRES does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .recommendedResolution, code: .undefinedCommand))
        case (.recommendedResolution, .class2(let class2State)):
            return .success(.recommendedResolution(class2State.recommendedResolution))
        case (.filterUsageTime, .class1):
            // We are emulating a Class 1 projector, so FILT does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .filterUsageTime, code: .undefinedCommand))
        case (.filterUsageTime, .class2(let class2State)):
            return .success(.filterUsageTime(class2State.filterUsageTime))
        case (.lampReplacementModelNumber, .class1):
            // We are emulating a Class 1 projector, so RLMP does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .lampReplacementModelNumber, code: .undefinedCommand))
        case (.lampReplacementModelNumber, .class2(let class2State)):
            return .success(.lampReplacementModelNumber(class2State.lampReplacementModelNumber))
        case (.filterReplacementModelNumber, .class1):
            // We are emulating a Class 1 projector, so RFIL does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .filterReplacementModelNumber, code: .undefinedCommand))
        case (.filterReplacementModelNumber, .class2(let class2State)):
            return .success(.filterReplacementModelNumber(class2State.filterReplacementModelNumber))
        case (.freeze, .class1):
            // We are emulating a Class 1 projector, so FREZ does not exist for Class 1
            return .failure(.init(pjLinkClass: .one, command: .freeze, code: .undefinedCommand))
        case (.freeze, .class2(let class2State)):
            return .success(.freeze(class2State.freeze))
        }
    }

    static func setResponse(
        for setRequest: PJLink.SetRequest,
        state: LockIsolated<PJLink.State>
    ) -> PJLink.SetResponse {
        let stateUnwrapped = state.value
        switch (setRequest, stateUnwrapped) {
        case (.power(let onOff), _):
            let newPowerStatus: PowerStatus
            switch (stateUnwrapped.power, onOff) {
            case (.standby, .on):
                newPowerStatus = .warmUp
            case (.lampOn, .off):
                newPowerStatus = .cooling
            case (.cooling, .on):
                newPowerStatus = .warmUp
            case (.warmUp, .off):
                newPowerStatus = .cooling
            default:
                newPowerStatus = stateUnwrapped.power
            }
            state.withValue { stateMutable in
                stateMutable.power = newPowerStatus
            }
            return .init(pjlinkClass: setRequest.class, command: .power, code: .ok)
        case let (.inputSwitchClass1(inputSwitch), .class1(class1State)):
            if class1State.inputSwitches.switches.firstIndex(of: inputSwitch) != nil {
                state.withValue { stateMutable in
                    stateMutable = .class1(class1State.withActiveInputSwitch(inputSwitch))
                }
                return .init(pjlinkClass: setRequest.class, command: .inputSwitch, code: .ok)
            } else {
                // Could not find the specified input switch in the list
                return .init(pjlinkClass: setRequest.class, command: .inputSwitch, code: .outOfParameter)
            }
        case (.inputSwitchClass1, .class2):
            return .init(pjlinkClass: setRequest.class, command: .inputSwitch, code: .outOfParameter)
        case let (.inputSwitchClass2(inputSwitch), .class2(class2State)):
            if class2State.inputSwitches.switches.firstIndex(of: inputSwitch) != nil {
                state.withValue { stateMutable in
                    stateMutable = .class2(class2State.withActiveInputSwitch(inputSwitch))
                }
                return .init(pjlinkClass: setRequest.class, command: .inputSwitch, code: .ok)
            } else {
                // Could not find the specified input switch in the list
                return .init(pjlinkClass: setRequest.class, command: .inputSwitch, code: .outOfParameter)
            }
        case (.inputSwitchClass2, .class1):
            return .init(pjlinkClass: setRequest.class, command: .inputSwitch, code: .outOfParameter)
        case (.avMute(let muteState), _):
            state.withValue { stateMutable in
                stateMutable.mute = muteState
            }
            return .init(pjlinkClass: setRequest.class, command: .avMute, code: .ok)
        case (.speakerVolume, .class1):
            return .init(pjlinkClass: setRequest.class, command: .speakerVolume, code: .undefinedCommand)
        case let (.speakerVolume(volumeAdjustment), .class2(class2State)):
            state.withValue { stateMutable in
                stateMutable = .class2(class2State.withSpeakerVolumeAdjustment(volumeAdjustment))
            }
            return .init(pjlinkClass: setRequest.class, command: .speakerVolume, code: .ok)
        case (.microphoneVolume, .class1):
            return .init(pjlinkClass: setRequest.class, command: .microphoneVolume, code: .undefinedCommand)
        case let (.microphoneVolume(volumeAdjustment), .class2(class2State)):
            state.withValue { stateMutable in
                stateMutable = .class2(class2State.withMicrophoneVolumeAdjustment(volumeAdjustment))
            }
            return .init(pjlinkClass: stateUnwrapped.class, command: .microphoneVolume, code: .ok)
        case (.freeze, .class1):
            return .init(pjlinkClass: setRequest.class, command: .freeze, code: .undefinedCommand)
        case let (.freeze(freeze), .class2(class2State)):
            state.withValue { stateMutable in
                stateMutable = .class2(class2State.withFreeze(freeze))
            }
            return .init(pjlinkClass: setRequest.class, command: .freeze, code: .ok)
        }
    }

    static func updateAuthStateOnSuccess(
        authState: LockIsolated<PJLink.ServerAuthState>
    ) {
        switch authState.value {
        case (.class1AuthResponseSent(let buffer4)):
            authState.setValue(.class1Authenticated(buffer4))
        case .class2AuthResponseSent(let buffer16):
            authState.setValue(.class2Authenticated(buffer16))
        default:
            break
        }
    }
}

extension NetworkChannel.State {

    var isFinished: Bool {
        switch self {
        case .failed, .cancelled: true
        default: false
        }
    }
}
