//
//  PJLink+Command.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

extension PJLink {
    public enum Command: String, Sendable, CaseIterable {
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

    public var classes: [PJLink.Class] {
        switch self {
        case .power: [.one]
        case .inputSwitch: [.one, .two]
        case .avMute: [.one]
        case .errorStatus: [.one]
        case .lamp: [.one]
        case .inputList: [.one, .two]
        case .projectorName:  [.one]
        case .manufacturerName: [.one]
        case .productName: [.one]
        case .otherInformation: [.one]
        case .projectorClass: [.one]
        case .serialNumber: [.two]
        case .softwareVersion: [.two]
        case .inputTerminalName: [.two]
        case .inputResolution: [.two]
        case .recommendedResolution: [.two]
        case .filterUsageTime: [.two]
        case .lampReplacementModelNumber: [.two]
        case .filterReplacementModelNumber: [.two]
        case .speakerVolume: [.two]
        case .microphoneVolume: [.two]
        case .freeze: [.two]
        }
    }

    public static let allSetCommands: [Self] = [
        .power, .inputSwitch, .avMute, .speakerVolume, .microphoneVolume, .freeze,
    ]

    public static let allGetCommands: [Self] = [
        .power, .inputSwitch, .avMute, .errorStatus, .lamp, .inputList, .projectorName, .manufacturerName,
        .productName, .otherInformation, .projectorClass, .serialNumber, .softwareVersion, .inputTerminalName,
        .inputResolution, .recommendedResolution, .filterUsageTime, .lampReplacementModelNumber,
        .filterReplacementModelNumber, .freeze,
    ]

    public static let allClass1Commands: [Self] = allCases.filter { $0.classes.contains(.one) }
    public static let allClass2Commands: [Self] = allCases.filter { $0.classes.contains(.two) }
}
