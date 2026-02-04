//
//  PJLink+Notification.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/2/26.
//

extension PJLink {

    public enum Notification: Equatable, Sendable {
        case linkup(MacAddress)
        case errorStatus(ErrorStatus)
        case power(OnOff)
        case input(InputSwitchClass2)

        public enum Command: String {
            case linkup = "LKUP"
            case errorStatus = "ERST"
            case power = "POWR"
            case input = "INPT"
        }
    }
}

extension PJLink.Notification: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        let pjlinkId = String(mutableDesc.prefix(1))
        guard pjlinkId == PJLink.identifier else {
            throw PJLink.Error.invalidID(pjlinkId)
        }
        mutableDesc.removeFirst(1)

        let classRawValue = String(mutableDesc.prefix(1))
        guard let pjlinkClass = PJLink.Class(rawValue: classRawValue), pjlinkClass == .two else {
            throw PJLink.Error.invalidClass(classRawValue)
        }
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Notification.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidNotificationCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorResponse else {
            throw PJLink.Error.invalidSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        let parameters = String(mutableDesc)
        switch pjlinkCommand {
        case .linkup:
            self = .linkup(try PJLink.MacAddress(parameters))
        case .errorStatus:
            self = .errorStatus(try PJLink.ErrorStatus(parameters))
        case .power:
            self = .power(try PJLink.OnOff(parameters))
        case .input:
            self = .input(try PJLink.InputSwitchClass2(parameters))
        }
    }

    public var description: String {
        PJLink.identifier + PJLink.Class.two.rawValue + command.rawValue + PJLink.separatorResponse + parameterDescription
    }
}

extension PJLink.Notification {

    public var command: Command {
        switch self {
        case .linkup: .linkup
        case .errorStatus: .errorStatus
        case .power: .power
        case .input: .input
        }
    }

    public var displayName: String {
        switch self {
        case .linkup: "Link Up"
        case .errorStatus: "Error Status"
        case .power: "Power"
        case .input: "Input"
        }
    }

    public var parameterDescription: String {
        switch self {
        case .linkup(let macAddress): macAddress.description
        case .errorStatus(let errorStatus): errorStatus.description
        case .power(let onOff): onOff.description
        case .input(let inputSwitchClass2): inputSwitchClass2.description
        }
    }
}

extension PJLink.Notification: CaseIterable {

    public static let allCases: [PJLink.Notification] = [
        .linkup(.mock),
        .errorStatus(.mock),
        .power(.on),
        .input(.mock)
    ]
}
