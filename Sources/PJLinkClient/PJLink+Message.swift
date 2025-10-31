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
            case code(ErrorResponse)
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
                case filterUsageTime(Int)
                case lampReplacementModelNumber(ModelNumber)
                case filterReplacementModelNumber(ModelNumber)
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
        if let errorResponse = PJLink.ErrorResponse(rawValue: parameters) {
            self = .code(errorResponse)
        } else {
            self = .body(try .init(pjlinkClass: pjlinkClass, command: command, parameters: parameters))
        }
    }

    public var description: String {
        switch self {
        case .code(let errorResponse): errorResponse.rawValue
        case .body(let body): body.description
        }
    }
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
            self = .projectorName(.init(value: parameters))
        case .manufacturerName:
            self = .manufacturerName(.init(value: parameters))
        case .productName:
            self = .productName(.init(value: parameters))
        case .otherInformation:
            self = .otherInformation(.init(value: parameters))
        case .projectorClass:
            guard let pjlinkClass = PJLink.Class(rawValue: parameters) else {
                throw PJLink.Error.invalidClass(parameters)
            }
            self = .projectorClass(pjlinkClass)
        case .serialNumber:
            self = .serialNumber(.init(value: parameters))
        case .softwareVersion:
            self = .softwareVersion(.init(value: parameters))
        case .inputTerminalName:
            self = .inputTerminalName(.init(value: parameters))
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
            self = .lampReplacementModelNumber(.init(value: parameters))
        case .filterReplacementModelNumber:
            self = .filterReplacementModelNumber(.init(value: parameters))
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
        case .filterUsageTime(let usageTime): "\(usageTime)"
        case .lampReplacementModelNumber(let modelNumber): modelNumber.value
        case .filterReplacementModelNumber(let modelNumber): modelNumber.value
        case .freeze(let freeze): freeze.rawValue
        }
    }
}
