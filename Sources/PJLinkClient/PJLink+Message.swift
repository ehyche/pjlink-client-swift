//
//  PJLink+Message.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

extension PJLink {
    public struct Message: Equatable {
        public var `class`: Class
        public var command: Command
        public var body: MessageBody
    }

    public enum MessageBody: Equatable {
        case request(Request)
        case response(Response)

        public enum Request: Equatable {
            case get(GetRequest)
            case set(SetRequest)
        }

        public enum Response: Equatable {
            case ok               // OK
            case undefinedCommand // ERR1
            case outOfParameter   // ERR2
            case unavailableTime  // ERR3
            case projectorFailure // ERR4
            case body(Body)

            public enum Body: Equatable {
                case power(PowerStatus)
                case inputSwitchClass1(InputSwitchClass1)
                case inputSwitchClass2(InputSwitchClass2)
                case avMute(MuteState)
                case errorStatus(ErrorStatus)
                case lamp(LampsStatus)
                case inputListClass1(InputSwitchesClass1)
                case inputListClass2(InputSwitchesClass2)
                case projectorName(String)
                case manufacturerName(String)
                case productName(String)
                case otherInformation(String)
                case projectorClass(PJLink.Class)
                case serialNumber(String)
                case softwareVersion(String)
                case inputTerminalName(String)
                case inputResolution(InputResolution)
                case recommendedResolution(Resolution)
                case filterUsageTime(Int)
                case lampReplacementModelNumber(String)
                case filterReplacementModelNumber(String)
                case freeze(Freeze)
            }
        }
    }
}

extension PJLink.Message: LosslessStringConvertibleThrowing {

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
        self.class = pjlinkClass
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        self.command = pjlinkCommand
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
                if pjlinkCommand == .inputTerminalName {
                    // INNM is the only get command that has parameters.
                    // Parse the InputSwitch parameter.
                    let inputSwitch = try PJLink.InputSwitchClass2(mutableDesc)
                    self.body = .request(.get(.inputTerminalName(inputSwitch)))
                } else {
                    // The rest of the get commands have no parameters, so
                    // we can just map directly from the command.
                    self.body = .request(.get(pjlinkCommand.getRequest))
                }
            } else {
                // Set Request
                self.body = .request(.set(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc)))
            }
        } else {
            // Response
            self.body = .response(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc))
        }
    }

    public var description: String {
        PJLink.identifier + self.class.rawValue + command.rawValue + body.separator + body.description
    }
}

extension PJLink.MessageBody {

    var separator: String {
        switch self {
        case .request: PJLink.separatorRequest
        case .response: PJLink.separatorResponse
        }
    }
}

extension PJLink.MessageBody: CustomStringConvertible {

    public var description: String {
        switch self {
        case .request(let request): request.description
        case .response(let response): response.description
        }
    }
}

extension PJLink.MessageBody.Request: CustomStringConvertible {

    public var description: String {
        switch self {
        case .get(let getRequest): getRequest.description
        case .set(let setRequest): setRequest.description
        }
    }
}

extension PJLink.MessageBody.Response {

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        switch parameters {
        case Self.okRawValue:
            self = .ok
        case Self.undefinedCommandRawValue:
            self = .undefinedCommand
        case Self.outOfParameterRawValue:
            self = .outOfParameter
        case Self.unavailableTimeRawValue:
            self = .unavailableTime
        case Self.projectorFailureRawValue:
            self = .projectorFailure
        default:
            self = .body(try .init(pjlinkClass: pjlinkClass, command: command, parameters: parameters))
        }
    }

    public var description: String {
        switch self {
        case .ok: Self.okRawValue
        case .undefinedCommand: Self.undefinedCommandRawValue
        case .outOfParameter: Self.outOfParameterRawValue
        case .unavailableTime: Self.unavailableTimeRawValue
        case .projectorFailure: Self.projectorFailureRawValue
        case .body(let body): body.description
        }
    }

    private static let okRawValue = "OK"
    private static let undefinedCommandRawValue = "ERR1"
    private static let outOfParameterRawValue = "ERR2"
    private static let unavailableTimeRawValue = "ERR3"
    private static let projectorFailureRawValue = "ERR4"
}

extension PJLink.MessageBody.Response.Body {

    init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        switch command {
        case .power:
            guard let powerStatus = PJLink.PowerStatus(rawValue: parameters) else {
                throw PJLink.Error.invalidPowerStatus(parameters)
            }
            self = .power(powerStatus)
        case .inputSwitch:
            switch pjlinkClass {
            case .one:
                self = .inputSwitchClass1(try .init(parameters))
            case .two:
                self = .inputSwitchClass2(try .init(parameters))
            }
        case .avMute:
            self = .avMute(try .init(parameters))
        case .errorStatus:
            self = .errorStatus(try .init(parameters))
        case .lamp:
            self = .lamp(try .init(parameters))
        case .inputList:
            switch pjlinkClass {
            case .one:
                self = .inputListClass1(try .init(parameters))
            case .two:
                self = .inputListClass2(try .init(parameters))
            }
        case .projectorName:
            self = .projectorName(parameters)
        case .manufacturerName:
            self = .manufacturerName(parameters)
        case .productName:
            self = .productName(parameters)
        case .otherInformation:
            self = .otherInformation(parameters)
        case .projectorClass:
            guard let pjlinkClass = PJLink.Class(rawValue: parameters) else {
                throw PJLink.Error.invalidClass(parameters)
            }
            self = .projectorClass(pjlinkClass)
        case .serialNumber:
            self = .serialNumber(parameters)
        case .softwareVersion:
            self = .softwareVersion(parameters)
        case .inputTerminalName:
            self = .inputTerminalName(parameters)
        case .inputResolution:
            self = .inputResolution(try .init(parameters))
        case .recommendedResolution:
            self = .recommendedResolution(try .init(parameters))
        case .filterUsageTime:
            guard let usageTime = Int(parameters) else {
                throw PJLink.Error.invalidFilterUsageTime(parameters)
            }
            self = .filterUsageTime(usageTime)
        case .lampReplacementModelNumber:
            self = .lampReplacementModelNumber(parameters)
        case .filterReplacementModelNumber:
            self = .filterReplacementModelNumber(parameters)
        case .freeze:
            guard let freeze = PJLink.Freeze(rawValue: parameters) else {
                throw PJLink.Error.invalidFreeze(parameters)
            }
            self = .freeze(freeze)
        default:
            throw PJLink.Error.unexpectedResponseForCommand(command)
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
        case .projectorName(let projectorName): projectorName
        case .manufacturerName(let manufacturerName): manufacturerName
        case .productName(let productName): productName
        case .otherInformation(let otherInformation): otherInformation
        case .projectorClass(let projectorClass): projectorClass.rawValue
        case .serialNumber(let serialNumber): serialNumber
        case .softwareVersion(let softwareVersion): softwareVersion
        case .inputTerminalName(let inputName): inputName
        case .inputResolution(let inputResolution): inputResolution.description
        case .recommendedResolution(let resolution): resolution.description
        case .filterUsageTime(let usageTime): "\(usageTime)"
        case .lampReplacementModelNumber(let modelNumber): modelNumber
        case .filterReplacementModelNumber(let modelNumber): modelNumber
        case .freeze(let freeze): freeze.rawValue
        }
    }
}
