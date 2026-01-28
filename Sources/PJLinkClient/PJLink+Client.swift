//
//  PJLink+Client.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/12/25.
//

import Foundation
import Network
import os
import PJLinkCommon

extension PJLink {

    public struct ConnectionState {
        public var connection: NetworkConnection<TCP>
        public var auth: AuthState
    }

    public struct Client {
        // Each client manages a single connection.
        // We may try multiple connections in the future.
        public var connectionState: ConnectionState
    }
}

extension PJLink.Client {

    public static func authenticate(
        on connection: NetworkConnection<TCP>,
        password: String?
    ) async throws -> PJLink.ConnectionState {
        let logger = Logger(sub: .client, cat: .connection)
        // Upon connection, we should receive either:
        // "PJLINK 0" (Authentication disabled); OR
        // "PJLINK 1 498e4a67" (Authentication enabled with 4-byte random number)
        let connectionResponse = try await connection.receive(atLeast: 9, atMost: 18).content
        let connectionResponseUTF8 = try connectionResponse.toUTF8String()
        logger.debug("RECV: \(connectionResponseUTF8)")
        print("RECV: \(connectionResponseUTF8)")
        let authResponse = try PJLink.AuthResponse(connectionResponseUTF8)

        guard authResponse != .authDisabled else {
            return .init(connection: connection, auth: .disabled)
        }

        guard case .securityLevel1(let randomNumber4Bytes) = authResponse else {
            throw PJLink.Error.unexpectedConnectionResponse(connectionResponseUTF8)
        }

        // The client then responds with "PJLINK 2\r" to check the security level.
        let requestString = PJLink.AuthRequest.securityLevel.description
        let requestStringTerminatedData = requestString.crTerminatedData
        try await connection.send(requestStringTerminatedData)
        logger.debug("SEND: \(requestString)")
        print("SEND: \(requestString)")

        // The projector should respond with "PJLINK 2 <hex-encoded-16-byte-random-number>\r"
        let securityLevelResponseData = try await connection.receive(atMost: 42).content
        let securityLevelUTF8 = try securityLevelResponseData.toUTF8String()
        logger.debug("RECV: \(securityLevelUTF8)")
        print("RECV: \(securityLevelUTF8)")
        let securityLevelResponse: PJLink.AuthResponse
        do {
            securityLevelResponse = try PJLink.AuthResponse(securityLevelUTF8)
        } catch {
            // We could not parse the response to "PJLINK 2\r".
            // So we assume a class 1 projector.
            securityLevelResponse = .securityLevel1(randomNumber4Bytes)
        }

        // At this point, we know we need a password. If we don't have it, then fail.
        guard let password else {
            throw PJLink.Error.noPasswordProvided
        }

        let authState: PJLink.AuthState
        switch securityLevelResponse {
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

    public static func updateAuthenticationState(
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.ConnectionState {
        let response = try await query(request: .projectorClass, from: connectionState)

        switch response {
        case .success:
            // We successfully authenticated, so change AuthState to .authenticated
            return .init(connection: connectionState.connection, auth: .authenticated)
        case .failure:
            // We failed, so we don't attempt to change the connectionState
            return connectionState
        }
    }

    public static func fetchState(from connectionState: PJLink.ConnectionState) async throws -> PJLink.State {
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

    public static func fetchClass1State(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Class1State {
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

    public static func fetchClass2State(from connectionState: PJLink.ConnectionState) async throws -> PJLink.Class2State {
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
        request: PJLink.Message,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Message {
        let response = try await fetchResponse(request: request, from: connectionState)

        guard response.isSuccessfulResponse else {
            throw PJLink.Error.projectorRespondedWithError(request: request.description, response: response.description)
        }

        return response
    }

    /// This method takes as input a request message and fetches the response.
    /// If the projector response is an error (i.e. - "ERR1", etc.), then this method does NOT
    /// throw an error.
    private static func fetchResponse(
        request: PJLink.Message,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.Message {
        let logger = Logger(sub: .client, cat: .connection)
        // Make sure the input message is a request
        guard request.isRequest else {
            throw PJLink.Error.inputMessageMustBeRequest(request.description)
        }
        let requestString = connectionState.auth.authString + request.description
        let requestStringTerminated = requestString.crTerminated

        try await connectionState.connection.send(Data(requestStringTerminated.utf8))
        logger.debug("SEND: \(requestString)")
        print("SEND: \(requestString)")

        let responseData = try await connectionState.connection.receive(atMost: PJLink.maxResponseSize).content
        let responseUTF8 = try responseData.toUTF8String()
        logger.debug("RECV: \(responseUTF8)")
        print("RECV: \(responseUTF8)")

        // As we are parsing, we give the PJLink.Message parser a hint
        // whether or not we are expecting a response to a set request.
        // If the request is a Set request, then we expect a Set response.
        let response = try PJLink.Message(responseUTF8, isSetResponseHint: request.isSetRequest)

        // Do some error-checking.
        //
        // We expect that the associated command in the response should
        // be the same as the command in the request.
        guard request.command == response.command else {
            throw PJLink.Error.unexpectedResponseCommand(request: request.command, response: response.command)
        }
        // We expect that if we had a set request, then we should have a set response.
        // Likewise, if we had a get request, then we should have a get response.
        guard request.isSetRequest == response.isSetResponse else {
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
    ) async throws -> PJLink.GetResponseSuccess {
        let response = try await query(request: request, from: connectionState)

        switch response {
        case .success(let getResponseSuccess):
            return getResponseSuccess
        case .failure(let getResponseFailure):
            throw PJLink.Error.queryFailed(request: request.description, code: getResponseFailure.code.rawValue)
        }
    }

    /// This method takes as input a request message and fetches the response.
    /// If the projector response is an error (i.e. - "ERR1", etc.), then this method does NOT
    /// throw an error.
    private static func query(
        request: PJLink.GetRequest,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.GetResponse {
        let logger = Logger(sub: .client, cat: .connection)
        let requestString = connectionState.auth.authString + request.description
        let requestStringTerminated = requestString.crTerminated

        try await connectionState.connection.send(Data(requestStringTerminated.utf8))
        logger.debug("SEND \(requestString)")
        print("SEND \(requestString)")

        let responseData = try await connectionState.connection.receive(atMost: PJLink.maxResponseSize).content
        let responseUTF8 = try responseData.toUTF8String()
        logger.debug("RECV: \(responseUTF8)")
        print("RECV: \(responseUTF8)")

        // As we are parsing, we give the PJLink.Message parser a hint
        // whether or not we are expecting a response to a set request.
        // If the request is a Set request, then we expect a Set response.
        let response = try PJLink.GetResponse(responseUTF8)

        // Do some error-checking.
        //
        // We expect that the associated command in the response should
        // be the same as the command in the request.
        guard request.command == response.command else {
            throw PJLink.Error.unexpectedResponseCommand(request: request.command, response: response.command)
        }

        return response
    }

    public static func setPower(
        to onOff: PJLink.OnOff,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.PowerStatus {
        // Set the power on or off
        try await setThrowing(request: .power(onOff), from: connectionState)
        // Fetch the power status
        return try await queryPowerStatus(from: connectionState)
    }

    public static func setInput(
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

    public static func setInputClass1(
        to inputSwitch: PJLink.InputSwitchClass1,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.InputSwitchClass1 {
        // Set the input
        try await setThrowing(request: .inputSwitchClass1(inputSwitch), from: connectionState)
        // Fetch the current input
        return try await queryInputSwitchClass1(from: connectionState)
    }

    public static func setInputClass2(
        to inputSwitch: PJLink.InputSwitchClass2,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.InputSwitchClass2 {
        // Set the input
        try await setThrowing(request: .inputSwitchClass2(inputSwitch), from: connectionState)
        // Fetch the current input
        return try await queryInputSwitchClass2(from: connectionState)
    }

    public static func setMuteState(
        to muteState: PJLink.MuteState,
        from connectionState: PJLink.ConnectionState
    ) async throws -> PJLink.MuteState {
        // Set the mute state
        try await setThrowing(request: .avMute(muteState), from: connectionState)
        // Fetch the current mute state
        return try await queryMuteState(from: connectionState)
    }

    public static func setSpeakerVolume(
        to volume: PJLink.VolumeAdjustment,
        from connectionState: PJLink.ConnectionState
    ) async throws {
        try await setThrowing(request: .speakerVolume(volume), from: connectionState)
    }

    public static func setMicrophoneVolume(
        to volume: PJLink.VolumeAdjustment,
        from connectionState: PJLink.ConnectionState
    ) async throws {
        try await setThrowing(request: .microphoneVolume(volume), from: connectionState)
    }

    public static func setFreeze(
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
    ) async throws -> PJLink.SetResponse {
        let logger = Logger(sub: .client, cat: .connection)
        let requestString = connectionState.auth.authString + request.description
        let requestStringTerminated = requestString.crTerminated

        try await connectionState.connection.send(Data(requestStringTerminated.utf8))
        logger.debug("SEND \(requestString)")
        print("SEND \(requestString)")

        let responseData = try await connectionState.connection.receive(atMost: PJLink.maxResponseSize).content
        let responseUTF8 = try responseData.toUTF8String()
        logger.debug("RECV: \(responseUTF8)")
        print("RECV: \(responseUTF8)")
        let response = try PJLink.SetResponse(responseUTF8)

        // Do some error-checking.
        //
        // We expect that the associated command in the response should
        // be the same as the command in the request.
        guard request.command == response.command else {
            throw PJLink.Error.unexpectedResponseCommand(request: request.command, response: response.command)
        }

        return response
    }
}
