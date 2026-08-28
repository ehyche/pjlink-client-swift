//
//  PJLink+Message.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

import Foundation

extension PJLink {

    public enum Message: Equatable, Sendable {
        case request(Request)
        case response(Response)
    }

    public enum Request: Equatable, Sendable {
        case auth(AuthRequest)
        case get(GetRequestWithAuth)
        case set(SetRequestWithAuth)
    }

    public enum Response: Equatable, Sendable {
        case auth(AuthResponse)
        case get(GetResponse)
        case status(StatusResponse)
    }
}

extension PJLink.Message: LosslessStringConvertibleThrowing {

    /// Initializer
    /// - Parameters:
    ///   - description: The string to parse
    public init(_ description: String) throws {
        // Check for AuthRequest ("PJLINK 2")
        guard description != PJLink.AuthRequest.securityLevel.description else {
            self = .request(.auth(.securityLevel))
            return
        }
        // Check for AuthResponse
        guard !description.hasPrefix(PJLink.pjlink) else {
            self = .response(.auth(try .init(description)))
            return
        }
        var mutableDesc = description
        guard let pctIndex = mutableDesc.firstIndex(of: PJLink.identifierCharacter) else {
            throw PJLink.Error.missingIdentifier
        }
        let authPrefixString = String(mutableDesc.prefix(upTo: pctIndex))
        if !authPrefixString.isEmpty {
            mutableDesc.removeSubrange(mutableDesc.startIndex..<pctIndex)
        }
        let authPrefix = try PJLink.AuthPrefix(authPrefixString)

        let pjlinkId = String(mutableDesc.prefix(1))
        guard pjlinkId == PJLink.identifier else {
            throw PJLink.Error.invalidID(pjlinkId)
        }
        mutableDesc.removeFirst(1)

        let classRawValue = String(mutableDesc.prefix(1))
        guard let pjlinkClass = PJLink.Class(rawValue: classRawValue) else {
            throw PJLink.Error.invalidClass(classRawValue)
        }
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorRequest || separator == PJLink.separatorResponse else {
            throw PJLink.Error.invalidSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        if separator == PJLink.separatorRequest {
            // Request
            if mutableDesc.prefix(1) == PJLink.prefixGet {
                // Get Request
                mutableDesc.removeFirst(1)
                self = .request(
                    .get(
                        .init(
                            try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc),
                            authPrefix: authPrefix
                        )
                    )
                )
            } else {
                // Set Request
                self = .request(
                    .set(
                        .init(
                            try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc),
                            authPrefix: authPrefix
                        )
                    )
                )
            }
        } else {
            // This is a response.
            self = .response(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc))
        }
    }

    public var description: String {
        switch self {
        case .request(let request): request.description
        case .response(let response): response.description
        }
    }
}

extension PJLink.Message {

    public var isRequest: Bool {
        switch self {
        case .request: true
        case .response: false
        }
    }

    public var isSetRequest: Bool {
        switch self {
        case .request(let request): request.isSet
        case .response: false
        }
    }

    public var isSetResponse: Bool {
        switch self {
        case .request: false
        case .response(let response): response.isStatus
        }
    }

    public var isSuccessfulResponse: Bool {
        switch self {
        case .request: false
        case .response(let response): response.isSuccess
        }
    }

    public var separator: String {
        switch self {
        case .request: PJLink.separatorRequest
        case .response: PJLink.separatorResponse
        }
    }

    public var command: PJLink.Command? {
        switch self {
        case .request(let request): request.command
        case .response(let response): response.command
        }
    }
}

extension PJLink.Request {

    public var isSet: Bool {
        switch self {
        case .set: true
        default: false
        }
    }

    public var `class`: PJLink.Class? {
        switch self {
        case .auth: nil
        case .get(let getRequestWithAuth): getRequestWithAuth.request.class
        case .set(let setRequestWithAuth): setRequestWithAuth.request.class
        }
    }

    public var command: PJLink.Command? {
        switch self {
        case .auth: nil
        case .get(let getRequestWithAuth): getRequestWithAuth.request.command
        case .set(let setRequestWithAuth): setRequestWithAuth.request.command
        }
    }
}

extension PJLink.Request: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        // Check for AuthRequest ("PJLINK 2")
        guard description != PJLink.AuthRequest.securityLevel.description else {
            self = .auth(.securityLevel)
            return
        }
        var mutableDesc = description
        guard let pctIndex = mutableDesc.firstIndex(of: PJLink.identifierCharacter) else {
            throw PJLink.Error.missingIdentifier
        }
        let authPrefixString = String(mutableDesc.prefix(upTo: pctIndex))
        if !authPrefixString.isEmpty {
            mutableDesc.removeSubrange(mutableDesc.startIndex..<pctIndex)
        }
        let authPrefix = try PJLink.AuthPrefix(authPrefixString)

        let pjlinkId = String(mutableDesc.prefix(1))
        guard pjlinkId == PJLink.identifier else {
            throw PJLink.Error.invalidID(pjlinkId)
        }
        mutableDesc.removeFirst(1)

        let classRawValue = String(mutableDesc.prefix(1))
        guard let pjlinkClass = PJLink.Class(rawValue: classRawValue) else {
            throw PJLink.Error.invalidClass(classRawValue)
        }
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorRequest else {
            throw PJLink.Error.invalidSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        // Request
        if mutableDesc.prefix(1) == PJLink.prefixGet {
            // Get Request
            mutableDesc.removeFirst(1)
            self = .get(
                .init(
                    try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc),
                    authPrefix: authPrefix
                )
            )
        } else {
            // Set Request
            self = .set(
                .init(
                    try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc),
                    authPrefix: authPrefix
                )
            )
        }
    }

    public var description: String {
        switch self {
        case .auth(let authRequest): authRequest.description
        case .get(let getRequest): getRequest.description
        case .set(let setRequest): setRequest.description
        }
    }
}

extension PJLink.Response {

    /// Initializer
    /// - Parameters:
    ///   - description: The string to parse
    public init(_ description: String) throws {
        var mutableDesc = description
        let pjlinkId = String(mutableDesc.prefix(1))
        guard pjlinkId == PJLink.identifier else {
            throw PJLink.Error.invalidID(pjlinkId)
        }
        mutableDesc.removeFirst(1)

        let classRawValue = String(mutableDesc.prefix(1))
        guard let pjlinkClass = PJLink.Class(rawValue: classRawValue) else {
            throw PJLink.Error.invalidClass(classRawValue)
        }
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorResponse else {
            throw PJLink.Error.invalidSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        try self.init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc)
    }

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        // Are the parameters a status code?
        if let statusCode = PJLink.ResponseCode(rawValue: parameters) {
            self = .status(.init(pjlinkClass: pjlinkClass, command: command, code: statusCode))
        } else {
            self = .get(try .init(pjlinkClass: pjlinkClass, command: command, parameters: parameters))
        }
    }

    public var `class`: PJLink.Class? {
        switch self {
        case .auth: nil
        case .get(let getSuccess): getSuccess.class
        case .status(let statusResponse): statusResponse.class
        }
    }

    public var command: PJLink.Command? {
        switch self {
        case .auth: nil
        case .get(let getSuccess): getSuccess.command
        case .status(let statusResponse): statusResponse.command
        }
    }

    public var isStatus: Bool {
        switch self {
        case .status: true
        default: false
        }
    }

    public var isSuccess: Bool {
        switch self {
        case .auth: false
        case .get: true
        case .status(let statusResponse): statusResponse.isOK
        }
    }
}

extension PJLink.Response: CustomStringConvertible {

    public var description: String {
        switch self {
        case .auth(let authResponse): authResponse.description
        case .get(let getSuccess): getSuccess.description
        case .status(let statusResponse): statusResponse.description
        }
    }
}

extension PJLink.Request {

    public static let setPowerOn: Self = .set(.init(.power(.on)))
    public static let setPowerOff: Self = .set(.init(.power(.off)))
    public static let getPower: Self = .get(.init(.power))
    public static func setInputSwitchClass1(_ inputSwitchClass1: PJLink.InputSwitchClass1) -> Self {
        .set(.init(.inputSwitchClass1(inputSwitchClass1)))
    }
    public static let getInputSwitchClass1: Self = .get(.init(.inputSwitchClass1))
    public static func setInputSwitchClass2(_ inputSwitchClass2: PJLink.InputSwitchClass2) -> Self {
        .set(.init(.inputSwitchClass2(inputSwitchClass2)))
    }
    public static let getInputSwitchClass2: Self = .get(.init(.inputSwitchClass2))
    public static func setAudioVideoMute(_ muteState: PJLink.MuteState) -> Self {
        .set(.init(.avMute(muteState)))
    }
    public static let setVideoMuteOn: Self = .set(.init(.avMute(.init(mute: .video, state: .on))))
    public static let setVideoMuteOff: Self = .set(.init(.avMute(.init(mute: .video, state: .off))))
    public static let setAudioMuteOn: Self = .set(.init(.avMute(.init(mute: .audio, state: .on))))
    public static let setAudioMuteOff: Self = .set(.init(.avMute(.init(mute: .audio, state: .off))))
    public static let setAudioVideoMuteOn: Self = .set(.init(.avMute(.init(mute: .audioVideo, state: .on))))
    public static let setAudioVideoMuteOff: Self = .set(.init(.avMute(.init(mute: .audioVideo, state: .off))))
    public static let getAudioVideoMute: Self = .get(.init(.avMute))
    public static let getErrorStatus: Self = .get(.init(.errorStatus))
    public static let getLamp: Self = .get(.init(.lamp))
    public static let getInputListClass1: Self = .get(.init(.inputListClass1))
    public static let getInputListClass2: Self = .get(.init(.inputListClass2))
    public static let getProjectorName: Self = .get(.init(.projectorName))
    public static let getManufacturerName: Self = .get(.init(.manufacturerName))
    public static let getProductName: Self = .get(.init(.productName))
    public static let getOtherInformation: Self = .get(.init(.otherInformation))
    public static let getProjectorClass: Self = .get(.init(.projectorClass))
    public static let getSerialNumber: Self = .get(.init(.serialNumber))
    public static let getSoftwareVersion: Self = .get(.init(.softwareVersion))
    public static func getInputTerminalName(_ inputSwitchClass2: PJLink.InputSwitchClass2) -> Self {
        .get(.init(.inputTerminalName(inputSwitchClass2)))
    }
    public static let getInputResolution: Self = .get(.init(.inputResolution))
    public static let getRecommendedResolution: Self = .get(.init(.recommendedResolution))
    public static let getFilterUsageTime: Self = .get(.init(.filterUsageTime))
    public static let getLampReplacementModelNumber: Self = .get(.init(.lampReplacementModelNumber))
    public static let getFilterReplacementModelNumber: Self = .get(.init(.filterReplacementModelNumber))
    public static let setSpeakerVolumeIncrease: Self = .set(.init(.speakerVolume(.increase)))
    public static let setSpeakerVolumeDecrease: Self = .set(.init(.speakerVolume(.decrease)))
    public static let setMicrophoneVolumeIncrease: Self = .set(.init(.microphoneVolume(.increase)))
    public static let setMicrophoneVolumeDecrease: Self = .set(.init(.microphoneVolume(.decrease)))
    public static let setFreezeStart: Self = .set(.init(.freeze(.start)))
    public static let setFreezeStop: Self = .set(.init(.freeze(.stop)))
    public static let getFreeze: Self = .get(.init(.freeze))
}

extension PJLink.Message {

    public static let requestSetPowerOn: Self = .request(.setPowerOn)
    public static let requestSetPowerOff: Self = .request(.setPowerOff)
    public static let requestGetPower: Self = .request(.getPower)
    public static func requestSetInputSwitchClass1(_ inputSwitchClass1: PJLink.InputSwitchClass1) -> Self {
        .request(.setInputSwitchClass1(inputSwitchClass1))
    }
    public static let requestGetInputSwitchClass1: Self = .request(.getInputSwitchClass1)
    public static func requestSetInputSwitchClass2(_ inputSwitchClass2: PJLink.InputSwitchClass2) -> Self {
        .request(.setInputSwitchClass2(inputSwitchClass2))
    }
    public static let requestGetInputSwitchClass2: Self = .request(.getInputSwitchClass2)
    public static func requestSetAudioVideoMute(_ muteState: PJLink.MuteState) -> Self {
        .request(.setAudioVideoMute(muteState))
    }
    public static let requestSetVideoMuteOn: Self = .request(.setVideoMuteOn)
    public static let requestSetVideoMuteOff: Self = .request(.setVideoMuteOff)
    public static let requestSetAudioMuteOn: Self = .request(.setAudioMuteOn)
    public static let requestSetAudioMuteOff: Self = .request(.setAudioMuteOff)
    public static let requestSetAudioVideoMuteOn: Self = .request(.setAudioVideoMuteOn)
    public static let requestSetAudioVideoMuteOff: Self = .request(.setAudioVideoMuteOff)
    public static let requestGetAudioVideoMute: Self = .request(.getAudioVideoMute)
    public static let requestGetErrorStatus: Self = .request(.getErrorStatus)
    public static let requestGetLamp: Self = .request(.getLamp)
    public static let requestGetInputListClass1: Self = .request(.getInputListClass1)
    public static let requestGetInputListClass2: Self = .request(.getInputListClass2)
    public static let requestGetProjectorName: Self = .request(.getProjectorName)
    public static let requestGetManufacturerName: Self = .request(.getManufacturerName)
    public static let requestGetProductName: Self = .request(.getProductName)
    public static let requestGetOtherInformation: Self = .request(.getOtherInformation)
    public static let requestGetProjectorClass: Self = .request(.getProjectorClass)
    public static let requestGetSerialNumber: Self = .request(.getSerialNumber)
    public static let requestGetSoftwareVersion: Self = .request(.getSoftwareVersion)
    public static func requestGetInputTerminalName(_ inputSwitchClass2: PJLink.InputSwitchClass2) -> Self {
        .request(.getInputTerminalName(inputSwitchClass2))
    }
    public static let requestGetInputResolution: Self = .request(.getInputResolution)
    public static let requestGetRecommendedResolution: Self = .request(.getRecommendedResolution)
    public static let requestGetFilterUsageTime: Self = .request(.getFilterUsageTime)
    public static let requestGetLampReplacementModelNumber: Self = .request(.getLampReplacementModelNumber)
    public static let requestGetFilterReplacementModelNumber: Self = .request(.getFilterReplacementModelNumber)
    public static let requestSetSpeakerVolumeIncrease: Self = .request(.setSpeakerVolumeIncrease)
    public static let requestSetSpeakerVolumeDecrease: Self = .request(.setSpeakerVolumeDecrease)
    public static let requestSetMicrophoneVolumeIncrease: Self = .request(.setMicrophoneVolumeIncrease)
    public static let requestSetMicrophoneVolumeDecrease: Self = .request(.setMicrophoneVolumeDecrease)
    public static let requestSetFreezeStart: Self = .request(.setFreezeStart)
    public static let requestSetFreezeStop: Self = .request(.setFreezeStop)
    public static let requestGetFreeze: Self = .request(.getFreeze)

    // Auth-related messages
    public static let responseAuthDisabled: Self = .response(.auth(.authDisabled))
    public static let requestAuthSecurityLevel: Self = .request(.auth(.securityLevel))
}
