//
//  PJLink+GetResponse.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 11/6/25.
//

extension PJLink {

    public enum GetResponse: Equatable, Sendable {
        case success(GetResponseSuccess)
        case failure(GetResponseFailure)
    }

    public enum GetResponseSuccess: Equatable, Sendable {
        case power(PowerStatus)
        case inputSwitchClass1(InputSwitchClass1)
        case inputSwitchClass2(InputSwitchClass2)
        case avMute(MuteState)
        case errorStatus(ErrorStatus)
        case lamp(LampsStatus)
        case inputListClass1(InputSwitchesClass1)
        case inputListClass2(InputSwitchesClass2)
        case projectorName(ProjectorName)
        case manufacturerName(ManufacturerName)
        case productName(ProductName)
        case otherInformation(OtherInformation)
        case projectorClass(PJLink.Class)
        case serialNumber(SerialNumber)
        case softwareVersion(SoftwareVersion)
        case inputTerminalName(InputTerminalName)
        case inputResolution(InputResolution)
        case recommendedResolution(Resolution)
        case filterUsageTime(FilterUsageTime)
        case lampReplacementModelNumber(ModelNumber)
        case filterReplacementModelNumber(ModelNumber)
        case freeze(Freeze)
    }

    public struct GetResponseFailure: Equatable, Sendable {
        public var `class`: PJLink.Class
        public var command: PJLink.Command
        public var code: GetResponseCode
    }

    public enum GetResponseCode: String, CaseIterable, Equatable, Sendable {
        case undefinedCommand = "ERR1"
        case outOfParameter = "ERR2"
        case unavailableTime = "ERR3"
        case projectorFailure = "ERR4"
    }
}

extension PJLink.GetResponse {

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        if let getResponseCode = PJLink.GetResponseCode(rawValue: parameters) {
            self = .failure(.init(class: pjlinkClass, command: command, code: getResponseCode))
        } else {
            self = .success(try .init(pjlinkClass: pjlinkClass, command: command, parameters: parameters))
        }
    }

    public var `class`: PJLink.Class {
        switch self {
        case .success(let getResponseSuccess): getResponseSuccess.class
        case .failure(let getResponseFailure): getResponseFailure.class
        }
    }

    public var command: PJLink.Command {
        switch self {
        case .success(let getResponseSuccess): getResponseSuccess.command
        case .failure(let getResponseFailure): getResponseFailure.command
        }
    }
}

extension PJLink.GetResponse: CustomStringConvertible {

    public var description: String {
        switch self {
        case .success(let getResponseSuccess): getResponseSuccess.description
        case .failure(let getResponseFailure): getResponseFailure.description
        }
    }
}

extension PJLink.GetResponseSuccess {

    init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        switch (pjlinkClass, command) {
        case (.one, .power):
            self = .power(try .init(parameters))
        case (.one, .inputSwitch):
            self = .inputSwitchClass1(try .init(parameters))
        case (.two, .inputSwitch):
            self = .inputSwitchClass2(try .init(parameters))
        case (.one, .avMute):
            self = .avMute(try .init(parameters))
        case (.one, .errorStatus):
            self = .errorStatus(try .init(parameters))
        case (.one, .lamp):
            self = .lamp(try .init(parameters))
        case (.one, .inputList):
            self = .inputListClass1(try .init(parameters))
        case (.two, .inputList):
            self = .inputListClass2(try .init(parameters))
        case (.one, .projectorName):
            self = .projectorName(.init(value: parameters))
        case (.one, .manufacturerName):
            self = .manufacturerName(.init(value: parameters))
        case (.one, .productName):
            self = .productName(.init(value: parameters))
        case (.one, .otherInformation):
            self = .otherInformation(.init(value: parameters))
        case (.one, .projectorClass):
            self = .projectorClass(try .init(parameters))
        case (.two, .serialNumber):
            self = .serialNumber(.init(value: parameters))
        case (.two, .softwareVersion):
            self = .softwareVersion(.init(value: parameters))
        case (.two, .inputTerminalName):
            self = .inputTerminalName(.init(value: parameters))
        case (.two, .inputResolution):
            self = .inputResolution(try .init(parameters))
        case (.two, .recommendedResolution):
            self = .recommendedResolution(try .init(parameters))
        case (.two , .filterUsageTime):
            self = .filterUsageTime(try .init(parameters))
        case (.two, .lampReplacementModelNumber):
            self = .lampReplacementModelNumber(.init(value: parameters))
        case (.two, .filterReplacementModelNumber):
            self = .filterReplacementModelNumber(.init(value: parameters))
        case (.two, .freeze):
            self = .freeze(try .init(parameters))
        default:
            throw PJLink.Error.unexpectedGetResponse(pjlinkClass, command)
        }
    }

    public var description: String {
        switch self {
        case .power(let powerStatus): powerStatus.rawValue
        case .inputSwitchClass1(let inputSwitch): inputSwitch.description
        case .inputSwitchClass2(let inputSwitch): inputSwitch.description
        case .avMute(let muteState): muteState.description
        case .errorStatus(let errorStatus): errorStatus.description
        case .lamp(let lampsStatus): lampsStatus.description
        case .inputListClass1(let inputSwitches): inputSwitches.description
        case .inputListClass2(let inputSwitches): inputSwitches.description
        case .projectorName(let projectorName): projectorName.value
        case .manufacturerName(let manufacturerName): manufacturerName.value
        case .productName(let productName): productName.value
        case .otherInformation(let otherInformation): otherInformation.value
        case .projectorClass(let projectorClass): projectorClass.rawValue
        case .serialNumber(let serialNumber): serialNumber.value
        case .softwareVersion(let softwareVersion): softwareVersion.value
        case .inputTerminalName(let inputName): inputName.value
        case .inputResolution(let inputResolution): inputResolution.description
        case .recommendedResolution(let resolution): resolution.description
        case .filterUsageTime(let usageTime): usageTime.description
        case .lampReplacementModelNumber(let modelNumber): modelNumber.value
        case .filterReplacementModelNumber(let modelNumber): modelNumber.value
        case .freeze(let freeze): freeze.rawValue
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
        case .inputListClass1, .inputListClass2: .inputSwitch
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

extension PJLink.GetResponseFailure: CustomStringConvertible {

    public var description: String { code.rawValue }
}
