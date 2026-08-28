//
//  PJLink+Client.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/12/25.
//

import ConcurrencyExtras
import Foundation
import Network
import os
import PJLinkCommon

extension PJLink {

    public struct ConnectionState: Sendable {
        public var connection: NetworkConnection<Coder<PJLink.Message, PJLink.Message, PJLink.NetworkPJLinkCoder>>
        public var auth: AuthState
    }

    public enum RetryState: Sendable {
        case notTried
        case success
        case recoverableFailure(count: Int)
        case unrecoverableFailure

        private static let maxAttempts = 3

        var shouldRetry: Bool {
            switch self {
            case .notTried: true
            case .success: false
            case .recoverableFailure(let count): count < Self.maxAttempts
            case .unrecoverableFailure: false
            }
        }

        var uponRecoverableFailure: Self {
            switch self {
            case .notTried: .recoverableFailure(count: 1)
            case .success: .success
            case .recoverableFailure(let count): .recoverableFailure(count: count + 1)
            case .unrecoverableFailure: .unrecoverableFailure
            }
        }
    }

    // A Client's job is to manage the state for a single projector.
    public struct Client: Sendable {
        // The IP address of the projector.
        public let host: NWEndpoint.Host
        // The password to authenticate with the projector.
        private let password: String?
        // Each client manages a single connection.
        // We may try multiple connections in the future.
        private var connectionState: ConnectionState
        // Each client also mananges the state for single projector.
        public let state = LockIsolated<PJLink.State?>(nil)

        public init(host: NWEndpoint.Host, password: String? = nil) {
            self.host = host
            self.password = password

            self.connectionState = Self.createConnectionState(host: host)
        }

        public mutating func resetConnectionState() {
            self.connectionState = Self.createConnectionState(host: host)
        }

        public mutating func setup() async throws {
            // This performs the handshake with the projector to determine how we authenticate.
            connectionState = try await Self.authenticate(on: connectionState.connection, password: password)
            // We do a first request so that we can successfully authenticate. If we are successful,
            // then we do not have to send an authentication string after that.
            if connectionState.auth.mustAuthenticate {
                connectionState = try await Self.updateAuthenticationState(from: connectionState)
            }
        }

        private mutating func withRetry(_ work: @Sendable (ConnectionState, LockIsolated<PJLink.State?>) async throws -> Void) async throws {
            let retryState = LockIsolated(RetryState.notTried)
            while retryState.value.shouldRetry {
                do {
                    try await work(connectionState, state)
                    retryState.withValue { $0 = .success }
                } catch {
                    Self.logError(error, prefix: "withRetry Connection[\(self.connectionState.connection.id)] ")
                    let shouldReconnect: Bool
                    if let nwError = error as? NWError {
                        shouldReconnect = nwError.shouldReconnect
                    } else if let pjlinkError = error as? PJLink.Error {
                        shouldReconnect = pjlinkError.shouldReconnect
                    } else {
                        shouldReconnect = false
                    }
                    if shouldReconnect {
                        retryState.withValue { $0 = $0.uponRecoverableFailure }
                        if retryState.value.shouldRetry {
                            resetConnectionState()
                            try await setup()
                        } else {
                            throw error
                        }
                    } else {
                        throw error
                    }
                }
            }
        }

        public mutating func refreshState() async throws {
            try await withRetry { connState, lockState in
                let newState = try await Self.fetchState(from: connState)
                lockState.setValue(newState)
            }
        }

        public mutating func setPower(to onOff: PJLink.OnOff) async throws {
            try await withRetry { connState, lockState in
                let powerStatus = try await Self.setPower(to: onOff, from: connState)
                lockState.withValue {
                    $0?.power = powerStatus
                }
            }
        }

        public mutating func setInput(to input: PJLink.Input) async throws {
            try await withRetry { connState, lockState in
                let newInput = try await Self.setInput(to: input, from: connState)
                lockState.withValue {
                    $0?.activeInput = newInput
                }
            }
        }

        public mutating func setMuteState(to muteState: PJLink.MuteState) async throws {
            try await withRetry { connState, lockState in
                let newMuteState = try await Self.setMuteState(to: muteState, from: connState)
                lockState.withValue {
                    $0?.mute = newMuteState
                }
            }
        }

        public mutating func setSpeakerVolume(to volume: PJLink.VolumeAdjustment) async throws {
            try await withRetry { connState, _ in
                try await Self.setSpeakerVolume(to: volume, from: connState)
            }
        }

        public mutating func setMicrophoneVolume(to volume: PJLink.VolumeAdjustment) async throws {
            try await withRetry { connState, _ in
                try await Self.setMicrophoneVolume(to: volume, from: connState)
            }
        }

        public mutating func setFreeze(to freeze: PJLink.Freeze) async throws {
            try await withRetry { connState, lockState in
                let newFreeze = try await Self.setFreeze(to: freeze, from: connState)
                lockState.withValue {
                    $0?.freeze = newFreeze
                }
            }
        }

        public var stateDescription: String {
            guard let projectorState = state.value else {
                return "Not Initialized"
            }
            return projectorState.description
        }

        public var inputs: [PJLink.Input] {
            return state.value?.inputs ?? []
        }

        public func handleNotification(_ notification: PJLink.Notification) {
            let logger = Logger(sub: .client, cat: .notification)
            logger.debug("Handling notification: \(notification.description, privacy: .public)")
            state.withValue {
                $0?.applyingNotification(notification)
            }
        }

        public static func isProjectorPresent(at host: NWEndpoint.Host) async -> Bool {
            let connection = NetworkConnection(to: .hostPort(host: host, port: .pjlink)) {
                TCP()
                    .connectionTimeout(1)
                    .persistTimeout(1)
            }

            let logger = Logger(sub: .client, cat: .connection)
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
                case .setup:
                    stateDesc = "Setup"
                case .waiting(let error):
                    stateDesc = "Waiting(\(error))"
                case .preparing:
                    stateDesc = "Preparing"
                case .ready:
                    stateDesc = "Ready"
                case .failed(let error):
                    stateDesc = "Failed(\(error))"
                case .cancelled:
                    stateDesc = "Cancelled"
                @unknown default:
                    stateDesc = "Unknown"
                }
                logger.debug("Connection[\(connection.id)] onStateUpdate: \(stateDesc, privacy: .public)")
            }
            do {
                // Upon connection, we should receive either:
                // "PJLINK 0" (Authentication disabled); OR
                // "PJLINK 1 498e4a67" (Authentication enabled with 4-byte random number)
                let connectionResponse = try await connection.receive(atLeast: 9, atMost: 18).content
                let connectionResponseUTF8 = try connectionResponse.toUTF8String()
                logger.debug("RECV: \(connectionResponseUTF8)")
                _ = try PJLink.AuthResponse(connectionResponseUTF8)
                // If we received any sort of AuthResponse and were able to parse it,
                // then we know we are talking to a projector.
                return true
            } catch {
                logger.debug("Connection[\(connection.id)] to host \"\(host.debugDescription, privacy: .public)\" returned error: \(error)")
                return false
            }
        }
    }
}

extension PJLink.Client {

    private static func createConnectionState(host: NWEndpoint.Host) -> PJLink.ConnectionState {
        let connection = NetworkConnection(to: .hostPort(host: host, port: .pjlink)) {
            Coder(PJLink.Message.self, using: .pjlink) {
                TCP()
            }
        }

        let logger = Logger(sub: .client, cat: .connection)
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
            case .setup:
                stateDesc = "Setup"
            case .waiting(let error):
                stateDesc = "Waiting(\(error))"
            case .preparing:
                stateDesc = "Preparing"
            case .ready:
                stateDesc = "Ready"
            case .failed(let error):
                stateDesc = "Failed(\(error))"
            case .cancelled:
                stateDesc = "Cancelled"
            @unknown default:
                stateDesc = "Unknown"
            }
            logger.debug("Connection[\(connection.id)] onStateUpdate: \(stateDesc, privacy: .public)")
        }

        return .init(connection: connection, auth: .indeterminate)
    }

    private static func authenticate(
        on connection: NetworkConnection<Coder<PJLink.Message, PJLink.Message, PJLink.NetworkPJLinkCoder>>,
        password: String?
    ) async throws -> PJLink.ConnectionState {
        let logger = Logger(sub: .client, cat: .connection)
        // Upon connection, we should receive either:
        // "PJLINK 0" (Authentication disabled); OR
        // "PJLINK 1 498e4a67" (Authentication enabled with 4-byte random number)
        let connectionResponse = try await connection.receive().content
        logger.debug("RECV: \(connectionResponse)")

        guard connectionResponse != .responseAuthDisabled else {
            // We received "PJLINK 0", so authentication is disabled
            return .init(connection: connection, auth: .disabled)
        }

        // We should have received something like "PJLINK 1 498e4a67".
        // If we didn't, then it's an error.
        guard case .response(.auth(.securityLevel1(let randomNumber4Bytes))) = connectionResponse else {
            throw PJLink.Error.unexpectedConnectionResponse(connectionResponse.description)
        }

        // Send a "PJLINK 2"
        let message: PJLink.Message = .requestAuthSecurityLevel
        try await connection.send(message)
        logger.debug("SEND: \(message.description)")

        // The projector should respond with "PJLINK 2 <hex-encoded-16-byte-random-number>\r"
        let securityLevelResponse = try await connection.receive().content
        logger.debug("RECV: \(securityLevelResponse)")

        guard case .response(.auth(let authResponse)) = securityLevelResponse else {
            throw PJLink.Error.unexpectedResponse(
                request: message.description,
                response: securityLevelResponse.description
            )
        }

        // At this point, we know we need a password. If we don't have it, then fail.
        guard let password else {
            throw PJLink.Error.noPasswordProvided
        }

        let authState: PJLink.AuthState
        switch authResponse {
        case .authDisabled:
            authState = .disabled
        case .securityLevel1(let buffer4):
            authState = .level1(projectorRandom: buffer4, password: password)
        case .securityLevel2(let buffer16):
            authState = .level2(clientRandom: try .init(Data.random(count: 16)), projectorRandom: buffer16, password: password)
        case .authError:
            // The projector responded with "ERRA" to our "PJLINK 2\r" request.
            // So we assume a class1-level security projector.
            authState = .level1(projectorRandom: randomNumber4Bytes, password: password)
        }

        return .init(connection: connection, auth: authState)
    }

    private static func updateAuthenticationState(
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.ConnectionState {
        let response = try await query(request: .projectorClass, from: connectionState)

        switch response {
        case .auth:
            // This is an AuthResponse, so don't change connectionState
            return connectionState
        case .get:
            // We successfully authenticated, so change AuthState to .authenticated
            return .init(connection: connectionState.connection, auth: .authenticated)
        case .status(let statusResponse):
            switch statusResponse.code {
            case .ok:
                // We successfully authenticated, so change AuthState to .authenticated
                return .init(connection: connectionState.connection, auth: .authenticated)
            default:
                // We failed, so we don't attempt to change the connectionState
                return connectionState
            }
        }
    }

    private static func fetchState(from connectionState: PJLink.ConnectionState) async throws -> PJLink.State {
        // Fetch the projector class
        let projectorClass = try await queryClass(from: connectionState)

        switch projectorClass {
        case .one:
            let class1State = try await fetchClass1State(from: connectionState)
            return .class1(class1State)
        case .two:
            let class2State = try await fetchClass2State(from: connectionState)
            return .class2(class2State)
        }
    }

    private static func fetchClass1State(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Class1State {
        // Fetch the power status
        let powerStatus = try await queryPowerStatus(from: connectionState)
        // Fetch the input switch
        let inputSwitch = try await queryInputSwitchClass1(from: connectionState)
        // Fetch the AV mute
        let muteState = try await queryMuteState(from: connectionState)
        // Fetch the error status
        let errorStatus = try await queryErrorStatus(from: connectionState)
        // Fetch the lamps status
        let lampsStatus = try await queryLampsStatus(from: connectionState)
        // Fetch the input list
        let inputList = try await queryInputListClass1(from: connectionState)
        // Fetch the projector name
        let projectorName = try await queryProjectorName(from: connectionState)
        // Fetch the manufacturer name
        let manufacturerName = try await queryManufacturerName(from: connectionState)
        // Fetch the product name
        let productName = try await queryProductName(from: connectionState)
        // Fetch the other information
        let otherInformation = try await queryOtherInformation(from: connectionState)

        return .init(
            power: powerStatus,
            mute: muteState,
            error: errorStatus,
            lamps: lampsStatus,
            inputSwitches: inputList,
            activeInputSwitch: inputSwitch,
            projectorName: projectorName,
            manufacturerName: manufacturerName,
            productName: productName,
            otherInformation: otherInformation
        )
    }

    private static func fetchClass2State(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Class2State {
        // Fetch the power status
        let powerStatus = try await queryPowerStatus(from: connectionState)
        // Fetch the input switch
        let inputSwitch = try await queryInputSwitchClass2(from: connectionState)
        // Fetch the AV mute
        let muteState = try await queryMuteState(from: connectionState)
        // Fetch the error status
        let errorStatus = try await queryErrorStatus(from: connectionState)
        // Fetch the lamps status
        let lampsStatus = try await queryLampsStatus(from: connectionState)
        // Fetch the input list
        let inputList = try await queryInputListClass2(from: connectionState)
        // Fetch the projector name
        let projectorName = try await queryProjectorName(from: connectionState)
        // Fetch the manufacturer name
        let manufacturerName = try await queryManufacturerName(from: connectionState)
        // Fetch the product name
        let productName = try await queryProductName(from: connectionState)
        // Fetch the other information
        let otherInformation = try await queryOtherInformation(from: connectionState)
        // Fetch the serial number
        let serialNumber = try await querySerialNumber(from: connectionState)
        // Fetch the software version
        let softwareVersion = try await querySoftwareVersion(from: connectionState)
        // Fetch the input resolution
        let inputResolution = try await queryInputResolution(from: connectionState)
        // Fetch the recommended resolution
        let recommendedResolution = try await queryRecommendedResolution(from: connectionState)
        // Fetch the filter usage time
        let filterUsageTime = try await queryFilterUsageTime(from: connectionState)
        // Fetch the lamp replacement model number
        let lampReplacementModelNumber = try await queryLampReplacementModelNumber(from: connectionState)
        // Fetch the filter replacement model number
        let filterReplacementModelNumber = try await queryFilterReplacementModelNumber(from: connectionState)
        // Fetch the freeze state
        let freeze = try await queryFreeze(from: connectionState)
        // Get the input terminal name for each InputSwitch in the list
        var inputNames = [PJLink.InputSwitchClass2: PJLink.InputTerminalName]()
        for inputSwitch in inputList.switches {
            let inputTerminalName = try await queryInputTerminalName(for: inputSwitch, from: connectionState)
            inputNames[inputSwitch] = inputTerminalName
        }

        return .init(
            power: powerStatus,
            mute: muteState,
            error: errorStatus,
            lamps: lampsStatus,
            inputSwitches: inputList,
            activeInputSwitch: inputSwitch,
            inputNames: inputNames,
            projectorName: projectorName,
            manufacturerName: manufacturerName,
            productName: productName,
            otherInformation: otherInformation,
            serialNumber: serialNumber,
            softwareVersion: softwareVersion,
            inputResolution: inputResolution,
            recommendedResolution: recommendedResolution,
            filterUsageTime: filterUsageTime,
            lampReplacementModelNumber: lampReplacementModelNumber,
            filterReplacementModelNumber: filterReplacementModelNumber,
            freeze: freeze
        )
    }

    /// This method takes as input a request message and fetches the response.
    /// If the projector response is an error (i.e. - "ERR1", etc.), then this method
    /// throws the error `PJLink.Error.projectorRespondedWithError`.
    private static func fetchResponseThrowing(
        request: PJLink.Request,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Response {
        let response = try await fetchResponse(request: request, from: connectionState)

        guard response.isSuccess else {
            throw PJLink.Error.projectorRespondedWithError(request: request.description, response: response.description)
        }

        return response
    }

    /// This method takes as input a request message and fetches the response.
    /// If the projector response is an error (i.e. - "ERR1", etc.), then this method does NOT
    /// throw an error.
    private static func fetchResponse(
        request: PJLink.Request,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Response {
        let logger = Logger(sub: .client, cat: .connection)

        let requestMessage: PJLink.Message = .request(request)
        try await connectionState.connection.send(requestMessage)
        logger.debug("SEND: \(requestMessage)")

        let responseMessage = try await connectionState.connection.receive().content
        logger.debug("RECV: \(responseMessage)")

        // Do some error-checking.
        //
        // This better be a response
        guard case .response(let response) = responseMessage else {
            throw PJLink.Error.unexpectedResponse(
                request: requestMessage.description,
                response: responseMessage.description
            )
        }
        // We expect that the associated command in the response should
        // be the same as the command in the request.
        if
            let requestCommand = requestMessage.command,
            let responseCommand = responseMessage.command,
            requestCommand != responseCommand {
            throw PJLink.Error.unexpectedResponseCommand(request: requestCommand, response: responseCommand)
        }
        // We expect that if we had a set request, then we should have a status response.
        // Likewise, if we had a get request, then we should have a get response.
        guard request.isSet == response.isStatus else {
            throw PJLink.Error.unexpectedResponse(request: request.description, response: response.description)
        }

        return response
    }

    private static func queryPowerStatus(from connectionState: PJLink.ConnectionState) async throws -> PJLink.PowerStatus {
        let response = try await queryThrowing(request: .power, from: connectionState)

        guard let powerStatus = response.powerStatus else {
            throw PJLink.Error.unexpectedResponseCommand(request: .power, response: response.command)
        }

        return powerStatus
    }

    private static func queryInputSwitchClass1(from connectionState: PJLink.ConnectionState) async throws -> PJLink.InputSwitchClass1 {
        let response = try await queryThrowing(request: .inputSwitchClass1, from: connectionState)

        guard let inputSwitchClass1 = response.inputSwitchClass1 else {
            throw PJLink.Error.unexpectedResponseCommand(request: .inputSwitch, response: response.command)
        }

        return inputSwitchClass1
    }

    private static func queryInputSwitchClass2(from connectionState: PJLink.ConnectionState) async throws -> PJLink.InputSwitchClass2 {
        let response = try await queryThrowing(request: .inputSwitchClass2, from: connectionState)

        guard let inputSwitchClass2 = response.inputSwitchClass2 else {
            throw PJLink.Error.unexpectedResponseCommand(request: .inputSwitch, response: response.command)
        }

        return inputSwitchClass2
    }

    private static func queryMuteState(from connectionState: PJLink.ConnectionState) async throws -> PJLink.MuteState {
        let response = try await queryThrowing(request: .avMute, from: connectionState)

        guard let muteState = response.muteState else {
            throw PJLink.Error.unexpectedResponseCommand(request: .avMute, response: response.command)
        }

        return muteState
    }

    private static func queryErrorStatus(from connectionState: PJLink.ConnectionState) async throws -> PJLink.ErrorStatus {
        let response = try await queryThrowing(request: .errorStatus, from: connectionState)

        guard let errorStatus = response.errorStatus else {
            throw PJLink.Error.unexpectedResponseCommand(request: .errorStatus, response: response.command)
        }

        return errorStatus
    }

    private static func queryLampsStatus(from connectionState: PJLink.ConnectionState) async throws -> PJLink.LampsStatus {
        let response = try await queryThrowing(request: .lamp, from: connectionState)

        guard let lampsStatus = response.lampsStatus else {
            throw PJLink.Error.unexpectedResponseCommand(request: .lamp, response: response.command)
        }

        return lampsStatus
    }

    private static func queryInputListClass1(from connectionState: PJLink.ConnectionState) async throws -> PJLink.InputSwitchesClass1 {
        let response = try await queryThrowing(request: .inputListClass1, from: connectionState)

        guard let inputList = response.inputListClass1 else {
            throw PJLink.Error.unexpectedResponseCommand(request: .inputList, response: response.command)
        }

        return inputList
    }

    private static func queryInputListClass2(from connectionState: PJLink.ConnectionState) async throws -> PJLink.InputSwitchesClass2 {
        let response = try await queryThrowing(request: .inputListClass2, from: connectionState)

        guard let inputList = response.inputListClass2 else {
            throw PJLink.Error.unexpectedResponseCommand(request: .inputList, response: response.command)
        }

        return inputList
    }

    private static func queryProjectorName(from connectionState: PJLink.ConnectionState) async throws -> PJLink.ProjectorName {
        let response = try await queryThrowing(request: .projectorName, from: connectionState)

        guard let projectorName = response.projectorName else {
            throw PJLink.Error.unexpectedResponseCommand(request: .projectorName, response: response.command)
        }

        return projectorName
    }

    private static func queryManufacturerName(from connectionState: PJLink.ConnectionState) async throws -> PJLink.ManufacturerName {
        let response = try await queryThrowing(request: .manufacturerName, from: connectionState)

        guard let manufacturerName = response.manufacturerName else {
            throw PJLink.Error.unexpectedResponseCommand(request: .manufacturerName, response: response.command)
        }

        return manufacturerName
    }

    private static func queryProductName(from connectionState: PJLink.ConnectionState) async throws -> PJLink.ProductName {
        let response = try await queryThrowing(request: .productName, from: connectionState)

        guard let productName = response.productName else {
            throw PJLink.Error.unexpectedResponseCommand(request: .productName, response: response.command)
        }

        return productName
    }

    private static func queryOtherInformation(from connectionState: PJLink.ConnectionState) async throws -> PJLink.OtherInformation {
        let response = try await queryThrowing(request: .otherInformation, from: connectionState)

        guard let otherInformation = response.otherInformation else {
            throw PJLink.Error.unexpectedResponseCommand(request: .otherInformation, response: response.command)
        }

        return otherInformation
    }

    private static func queryClass(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Class {
        let response = try await queryThrowing(request: .projectorClass, from: connectionState)

        guard let projectorClass = response.projectorClass else {
            throw PJLink.Error.unexpectedResponseCommand(request: .projectorClass, response: response.command)
        }

        return projectorClass
    }

    private static func querySerialNumber(from connectionState: PJLink.ConnectionState) async throws -> PJLink.SerialNumber {
        let response = try await queryThrowing(request: .serialNumber, from: connectionState)

        guard let serialNumber = response.serialNumber else {
            throw PJLink.Error.unexpectedResponseCommand(request: .serialNumber, response: response.command)
        }

        return serialNumber
    }

    private static func querySoftwareVersion(from connectionState: PJLink.ConnectionState) async throws -> PJLink.SoftwareVersion {
        let response = try await queryThrowing(request: .softwareVersion, from: connectionState)

        guard let softwareVersion = response.softwareVersion else {
            throw PJLink.Error.unexpectedResponseCommand(request: .softwareVersion, response: response.command)
        }

        return softwareVersion
    }

    private static func queryInputTerminalName(
        for inputSwitch: PJLink.InputSwitchClass2,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.InputTerminalName {
        let request: PJLink.GetRequest = .inputTerminalName(inputSwitch)
        let response = try await queryThrowing(request: request, from: connectionState)

        guard let inputTerminalName = response.inputTerminalName else {
            throw PJLink.Error.unexpectedResponseCommand(request: .inputTerminalName, response: response.command)
        }

        return inputTerminalName
    }

    private static func queryInputResolution(from connectionState: PJLink.ConnectionState) async throws -> PJLink.InputResolution {
        let response = try await queryThrowing(request: .inputResolution, from: connectionState)

        guard let inputResolution = response.inputResolution else {
            throw PJLink.Error.unexpectedResponseCommand(request: .inputResolution, response: response.command)
        }

        return inputResolution
    }

    private static func queryRecommendedResolution(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Resolution {
        let response = try await queryThrowing(request: .recommendedResolution, from: connectionState)

        guard let recommendedResolution = response.recommendedResolution else {
            throw PJLink.Error.unexpectedResponseCommand(request: .recommendedResolution, response: response.command)
        }

        return recommendedResolution
    }

    private static func queryFilterUsageTime(from connectionState: PJLink.ConnectionState) async throws -> PJLink.FilterUsageTime {
        let response = try await queryThrowing(request: .filterUsageTime, from: connectionState)

        guard let filterUsageTime = response.filterUsageTime else {
            throw PJLink.Error.unexpectedResponseCommand(request: .filterUsageTime, response: response.command)
        }

        return filterUsageTime
    }

    private static func queryLampReplacementModelNumber(from connectionState: PJLink.ConnectionState) async throws -> PJLink.ModelNumber {
        let response = try await queryThrowing(request: .lampReplacementModelNumber, from: connectionState)

        guard let modelNumber = response.lampReplacementModelNumber else {
            throw PJLink.Error.unexpectedResponseCommand(request: .lampReplacementModelNumber, response: response.command)
        }

        return modelNumber
    }

    private static func queryFilterReplacementModelNumber(from connectionState: PJLink.ConnectionState) async throws -> PJLink.ModelNumber {
        let response = try await queryThrowing(request: .filterReplacementModelNumber, from: connectionState)

        guard let modelNumber = response.filterReplacementModelNumber else {
            throw PJLink.Error.unexpectedResponseCommand(request: .filterReplacementModelNumber, response: response.command)
        }

        return modelNumber
    }

    private static func queryFreeze(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Freeze {
        let response = try await queryThrowing(request: .freeze, from: connectionState)

        guard let freeze = response.freeze else {
            throw PJLink.Error.unexpectedResponseCommand(request: .freeze, response: response.command)
        }

        return freeze
    }

    /// This method takes as input a query request message and fetches the response.
    /// If the projector response is an error (i.e. - "ERR1", etc.), then this method throws
    /// the `PJLink.Error.queryFailed` error.
    private static func queryThrowing(
        request: PJLink.GetRequest,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.GetResponse {
        let response = try await query(request: request, from: connectionState)

        switch response {
        case .auth:
            throw PJLink.Error.unexpectedGetResponse(response.description)
        case .get(let getSuccess):
            return getSuccess
        case .status(let statusResponse):
            throw PJLink.Error.queryFailed(request: request.description, code: statusResponse.code.rawValue)
        }
    }

    /// This method takes as input a request message and fetches the response.
    /// If the projector response is an error (i.e. - "ERR1", etc.), then this method does NOT
    /// throw an error.
    private static func query(
        request: PJLink.GetRequest,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Response {
        let logger = Logger(sub: .client, cat: .connection)

        let requestMessage: PJLink.Message = .request(
            .get(
                .init(request, authPrefix: try connectionState.auth.authPrefix)
            )
        )
        try await connectionState.connection.send(requestMessage)
        logger.debug("SEND \(requestMessage)")

        let responseMessage = try await connectionState.connection.receive().content
        logger.debug("RECV: \(responseMessage)")

        // Do some error-checking.
        //
        // This better be a response
        guard case .response(let response) = responseMessage else {
            throw PJLink.Error.unexpectedResponse(request: requestMessage.description, response: responseMessage.description)
        }

        // We expect that the associated command in the response should
        // be the same as the command in the request.
        if let responseCommand = responseMessage.command, request.command != responseCommand {
            throw PJLink.Error.unexpectedResponseCommand(request: request.command, response: responseCommand)
        }

        return response
    }

    private static func setPower(
        to onOff: PJLink.OnOff,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.PowerStatus {
        // Set the power on or off
        try await setThrowing(request: .power(onOff), from: connectionState)
        // Fetch the power status
        return try await queryPowerStatus(from: connectionState)
    }

    private static func setInput(
        to input: PJLink.Input,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Input {
        switch input {
        case .class1(let inputSwitchClass1):
            return .class1(try await setInputClass1(to: inputSwitchClass1, from: connectionState))
        case let .class2(inputSwitchClass2, inputTerminalName):
            return .class2(try await setInputClass2(to: inputSwitchClass2, from: connectionState), inputTerminalName)
        }
    }

    private static func setInputClass1(
        to inputSwitch: PJLink.InputSwitchClass1,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.InputSwitchClass1 {
        // Set the input
        try await setThrowing(request: .inputSwitchClass1(inputSwitch), from: connectionState)
        // Fetch the current input
        return try await queryInputSwitchClass1(from: connectionState)
    }

    private static func setInputClass2(
        to inputSwitch: PJLink.InputSwitchClass2,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.InputSwitchClass2 {
        // Set the input
        try await setThrowing(request: .inputSwitchClass2(inputSwitch), from: connectionState)
        // Fetch the current input
        return try await queryInputSwitchClass2(from: connectionState)
    }

    private static func setMuteState(
        to muteState: PJLink.MuteState,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.MuteState {
        // Set the mute state
        try await setThrowing(request: .avMute(muteState), from: connectionState)
        // Fetch the current mute state
        return try await queryMuteState(from: connectionState)
    }

    private static func setSpeakerVolume(
        to volume: PJLink.VolumeAdjustment,
        from connectionState: PJLink.ConnectionState
    ) async throws {
        try await setThrowing(request: .speakerVolume(volume), from: connectionState)
    }

    private static func setMicrophoneVolume(
        to volume: PJLink.VolumeAdjustment,
        from connectionState: PJLink.ConnectionState
    ) async throws {
        try await setThrowing(request: .microphoneVolume(volume), from: connectionState)
    }

    private static func setFreeze(
        to freeze: PJLink.Freeze,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Freeze {
        // Set the freeze state
        try await setThrowing(request: .freeze(freeze), from: connectionState)
        // Fetch the current freeze state
        return try await queryFreeze(from: connectionState)
    }

    private static func setThrowing(
        request: PJLink.SetRequest,
        from connectionState: PJLink.ConnectionState
    ) async throws {
        let response = try await set(request: request, from: connectionState)
        switch response.code {
        case .ok:
            break
        default:
            throw PJLink.Error.setFailed(request: request.description, code: response.code.rawValue)
        }
    }

    private static func set(
        request: PJLink.SetRequest,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.StatusResponse {
        let logger = Logger(sub: .client, cat: .connection)
        let requestMessage: PJLink.Message = .request(.set(.init(request, authPrefix: try connectionState.auth.authPrefix)))

        try await connectionState.connection.send(requestMessage)
        logger.debug("SEND \(requestMessage)")

        let responseMessage = try await connectionState.connection.receive().content
        logger.debug("RECV: \(responseMessage)")

        // Do some error-checking.
        //
        // This better be a status response
        guard case .response(.status(let response)) = requestMessage else {
            throw PJLink.Error.unexpectedResponse(
                request: requestMessage.description,
                response: responseMessage.description
            )
        }
        // We expect that the associated command in the response should
        // be the same as the command in the request.
        if let responseCommand = responseMessage.command, request.command != responseCommand {
            throw PJLink.Error.unexpectedResponseCommand(request: request.command, response: response.command)
        }

        return response
    }

    private static func logError(_ error: Swift.Error, prefix: String = "") {
        let logger = Logger(sub: .client, cat: .connection)
        if let nwError = error as? NWError {
            switch nwError {
            case .posix(let posixErrorCode):
                logger.error("\(prefix, privacy: .public)NWError.posix(\(posixErrorCode.rawValue)): \(nwError)")
            case .dns(let dnsServiceErrorType):
                logger.error("\(prefix, privacy: .public)NWError.dns(\(dnsServiceErrorType))")
            case .tls(let osStatus):
                logger.error("\(prefix, privacy: .public)NWError.tls(\(osStatus))")
            case .wifiAware(let errorCode):
                logger.error("\(prefix, privacy: .public)NWError.wifiAware(\(errorCode))")
            @unknown default:
                logger.error("\(prefix, privacy: .public)NWError.unknownDefault: \(nwError)")
            }
        } else if let pjlinkError = error as? PJLink.Error {
            logger.error("\(prefix, privacy: .public)PJLink.Error: \(pjlinkError)")
        } else {
            logger.error("\(prefix, privacy: .public)General Error: \(error)")
        }
    }
}
