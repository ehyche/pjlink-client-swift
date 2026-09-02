//
//  PJLink+Request.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 9/2/26.
//

extension PJLink {

    public enum Request: Equatable, Sendable {
        case auth(AuthRequest)
        case get(GetRequestWithAuth)
        case set(SetRequestWithAuth)
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

extension PJLink.Request: PJLink.MessageSizeRange {

    public var messageSizeRange: ClosedRange<Int> {
        switch self {
        case .auth(let authRequest): authRequest.messageSizeRange
        case .get(let getRequestWithAuth): getRequestWithAuth.messageSizeRange
        case .set(let setRequestWithAuth): setRequestWithAuth.messageSizeRange
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

extension PJLink.Request: CaseIterable {

    public static var allCases: [Self] {
        PJLink.AuthRequest.allCases.map(PJLink.Request.auth) +
        PJLink.GetRequestWithAuth.allCases.map(PJLink.Request.get) +
        PJLink.SetRequestWithAuth.allCases.map(PJLink.Request.set)
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
