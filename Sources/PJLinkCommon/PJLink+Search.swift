//
//  PJLink+Search.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/17/26.
//

extension PJLink {

    public enum Search: Equatable, Sendable {
        case request
        case response(MacAddress)

        public enum Command: String {
            case search = "SRCH"
            case acknowledge = "ACKN"
        }
    }
}

extension PJLink.Search: LosslessStringConvertibleThrowing {

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
        guard let pjlinkCommand = PJLink.Search.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidSearchCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        switch pjlinkCommand {
        case .search:
            // There is nothing else after the SRCH command
            self = .request
        case .acknowledge:
            let separator = String(mutableDesc.prefix(1))
            guard separator == PJLink.separatorResponse else {
                throw PJLink.Error.invalidSeparator(separator)
            }
            mutableDesc.removeFirst(1)
            self = .response(try .init(String(mutableDesc)))
        }
    }

    public var description: String {
        PJLink.identifier + self.class.rawValue + command.rawValue + separator + parameterDescription
    }
}

extension PJLink.Search {

    var `class`: PJLink.Class { .two }

    var command: Command {
        switch self {
        case .request: .search
        case .response: .acknowledge
        }
    }

    var separator: String {
        switch self {
        case .request: ""
        case .response: PJLink.separatorResponse
        }
    }

    var parameterDescription: String {
        switch self {
        case .request: ""
        case .response(let macAddress): macAddress.description
        }
    }
}
