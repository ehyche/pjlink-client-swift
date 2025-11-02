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
        switch (pjlinkClass, command) {
        case (.one, .power):
            self = .power
        case (.one, .inputSwitch):
            self = .inputSwitchClass1
        case (.two, .inputSwitch):
            self = .inputSwitchClass2
        case (.one, .avMute):
            self = .avMute
        case (.one, .errorStatus):
            self = .errorStatus
        case (.one, .lamp):
            self = .lamp
        case (.one, .inputList):
            self = .inputListClass1
        case (.two, .inputList):
            self = .inputListClass2
        case (.one, .projectorName):
            self = .projectorName
        case (.one, .manufacturerName):
            self = .manufacturerName
        case (.one, .productName):
            self = .productName
        case (.one, .otherInformation):
            self = .otherInformation
        case (.one, .projectorClass):
            self = .projectorClass
        case (.two, .serialNumber):
            self = .serialNumber
        case (.two, .softwareVersion):
            self = .softwareVersion
        case (.two, .inputTerminalName):
            self = .inputTerminalName(try .init(parameters))
        case (.two, .inputResolution):
            self = .inputResolution
        case (.two, .recommendedResolution):
            self = .recommendedResolution
        case (.two, .filterUsageTime):
            self = .filterUsageTime
        case (.two, .lampReplacementModelNumber):
            self = .lampReplacementModelNumber
        case (.two, .filterReplacementModelNumber):
            self = .filterReplacementModelNumber
        case (.two, .freeze):
            self = .freeze
        default:
            throw PJLink.Error.unexpectedGetRequest(pjlinkClass, command)
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
