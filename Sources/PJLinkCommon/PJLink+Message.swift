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

    public init(_ data: Data) throws {
        guard let utf8 = String(data: data, encoding: .utf8) else {
            throw PJLink.Error.couldNotCreateUTF8StringFromData(data)
        }
        try self.init(utf8.removingCRSuffix)
    }

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
