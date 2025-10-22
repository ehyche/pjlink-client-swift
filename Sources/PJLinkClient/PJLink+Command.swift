//
//  PJLink+Command.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

extension PJLink {
    public enum Command: String, Sendable {
        case power = "POWR"
        case inputSwitch = "INPT"
        case avMute = "AVMT"
        case errorStatus = "ERST"
        case lamp = "LAMP"
        case inputList = "INST"
        case projectorName = "NAME"
        case manufacturerName = "INF1"
        case productName = "INF2"
        case otherInformation = "INFO"
        case projectorClass = "CLSS"
        case serialNumber = "SNUM"
        case softwareVersion = "SVER"
        case inputTerminalName = "INNM"
        case inputResolution = "IRES"
        case recommendedResolution = "RRES"
        case filterUsageTime = "FILT"
        case lampReplacementModelNumber = "RLMP"
        case filterReplacementModelNumber = "RFIL"
        case speakerVolume = "SVOL"
        case microphoneVolume = "MVOL"
        case freeze = "FREZ"
    }
}

extension PJLink.Command {

    public var getRequest: PJLink.GetRequest {
        switch self {
        case .power: .power
        case .inputSwitch: .inputSwitch
        case .avMute: .avMute
        case .errorStatus: .errorStatus
        case .lamp: .lamp
        case .inputList: .inputList
        case .projectorName: .projectorName
        case .manufacturerName: .manufacturerName
        case .productName: .productName
        case .otherInformation: .otherInformation
        case .projectorClass: .projectorClass
        case .serialNumber: .serialNumber
        case .softwareVersion: .softwareVersion
        case .inputTerminalName: .inputTerminalName(.init(input: .rgb, channel: .one)) // Dummy value - not used
        case .inputResolution: .inputResolution
        case .recommendedResolution: .recommendedResolution
        case .filterUsageTime: .filterUsageTime
        case .lampReplacementModelNumber: .lampReplacementModelNumber
        case .filterReplacementModelNumber: .filterReplacementModelNumber
        case .speakerVolume: .speakerVolume
        case .microphoneVolume: .microphoneVolume
        case .freeze: .freeze
        }
    }
}
