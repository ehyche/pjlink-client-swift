//
//  File.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum GetRequest: Equatable {
        case power
        case inputSwitchClass1
        case inputSwitchClass2
        case avMute
        case errorStatus
        case lamp
        case inputListClass1
        case inputListClass2
        case projectorName
        case manufacturerName
        case productName
        case otherInformation
        case projectorClass
        case serialNumber
        case softwareVersion
        case inputTerminalName(InputSwitchClass2)
        case inputResolution
        case recommendedResolution
        case filterUsageTime
        case lampReplacementModelNumber
        case filterReplacementModelNumber
        case freeze
    }
}

extension PJLink.GetRequest {

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        switch (pjlinkClass, command, parameters.isEmpty) {
        case (.one, .power, true):
            self = .power
        case (.one, .inputSwitch, true):
            self = .inputSwitchClass1
        case (.two, .inputSwitch, true):
            self = .inputSwitchClass2
        case (.one, .avMute, true):
            self = .avMute
        case (.one, .errorStatus, true):
            self = .errorStatus
        case (.one, .lamp, true):
            self = .lamp
        case (.one, .inputList, true):
            self = .inputListClass1
        case (.two, .inputList, true):
            self = .inputListClass2
        case (.one, .projectorName, true):
            self = .projectorName
        case (.one, .manufacturerName, true):
            self = .manufacturerName
        case (.one, .productName, true):
            self = .productName
        case (.one, .otherInformation, true):
            self = .otherInformation
        case (.one, .projectorClass, true):
            self = .projectorClass
        case (.two, .serialNumber, true):
            self = .serialNumber
        case (.two, .softwareVersion, true):
            self = .softwareVersion
        case (.two, .inputTerminalName, false):
            self = .inputTerminalName(try .init(parameters))
        case (.two, .inputResolution, true):
            self = .inputResolution
        case (.two, .recommendedResolution, true):
            self = .recommendedResolution
        case (.two, .filterUsageTime, true):
            self = .filterUsageTime
        case (.two, .lampReplacementModelNumber, true):
            self = .lampReplacementModelNumber
        case (.two, .filterReplacementModelNumber, true):
            self = .filterReplacementModelNumber
        case (.two, .freeze, true):
            self = .freeze
        default:
            throw PJLink.Error.unexpectedGetRequest(pjlinkClass, command, parameters)
        }
    }

    public var `class`: PJLink.Class {
        switch self {
        case .power: .one
        case .inputSwitchClass1: .one
        case .inputSwitchClass2: .two
        case .avMute: .one
        case .errorStatus: .one
        case .lamp: .one
        case .inputListClass1: .one
        case .inputListClass2: .two
        case .projectorName: .one
        case .manufacturerName: .one
        case .productName: .one
        case .otherInformation: .one
        case .projectorClass: .one
        case .serialNumber: .two
        case .softwareVersion: .two
        case .inputTerminalName: .two
        case .inputResolution: .two
        case .recommendedResolution: .two
        case .filterUsageTime: .two
        case .lampReplacementModelNumber: .two
        case .filterReplacementModelNumber: .two
        case .freeze: .two
        }
    }

    public var command: PJLink.Command {
        switch self {
        case .power: .power
        case .inputSwitchClass1, .inputSwitchClass2: .inputSwitch
        case .avMute: .avMute
        case .errorStatus: .errorStatus
        case .lamp: .lamp
        case .inputListClass1, .inputListClass2: .inputList
        case .projectorName: .projectorName
        case .manufacturerName: .manufacturerName
        case .productName: .productName
        case .otherInformation: .otherInformation
        case .projectorClass: .projectorClass
        case .serialNumber: .serialNumber
        case .softwareVersion: .softwareVersion
        case .inputTerminalName: .inputTerminalName
        case .inputResolution: .inputResolution
        case .recommendedResolution: .recommendedResolution
        case .filterUsageTime: .filterUsageTime
        case .lampReplacementModelNumber: .lampReplacementModelNumber
        case .filterReplacementModelNumber: .filterReplacementModelNumber
        case .freeze: .freeze
        }
    }
}

extension PJLink.GetRequest: CustomStringConvertible {

    public var description: String {
        switch self {
        case .inputTerminalName(let inputSwitch): PJLink.prefixGet + inputSwitch.description
        default: PJLink.prefixGet
        }
    }
}
