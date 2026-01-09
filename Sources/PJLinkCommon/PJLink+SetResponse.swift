//
//  PJLink+SetResponse.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/23/25.
//

extension PJLink {

    public struct SetResponse: Equatable, Sendable {
        public var `class`: PJLink.Class
        public var command: PJLink.Command
        public var code: SetResponseCode
    }

    public enum SetResponseCode: String, CaseIterable, Sendable {
        case ok = "OK"
        case undefinedCommand = "ERR1"
        case outOfParameter = "ERR2"
        case unavailableTime = "ERR3"
        case projectorFailure = "ERR4"
    }
}

extension PJLink.SetResponseCode: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let setResponseCode = PJLink.SetResponseCode(rawValue: description) else {
            throw PJLink.Error.invalidSetResponseCode(description)
        }
        self = setResponseCode
    }

    public var description: String { rawValue }
}

extension PJLink.SetResponseCode {

    public var isOK: Bool {
        switch self {
        case .ok: true
        default: false
        }
    }
}

extension PJLink.SetResponse {

    public var isOK: Bool { code.isOK }
}

extension PJLink.SetResponse: LosslessStringConvertibleThrowing {

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
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorResponse else {
            let error: PJLink.Error = separator == PJLink.separatorRequest ?
                .unexpectedSetResponse(description) :
                .invalidSeparator(separator)
            throw error
        }
        mutableDesc.removeFirst(1)

        self = .init(
            class: pjlinkClass,
            command: pjlinkCommand,
            code: try PJLink.SetResponseCode(mutableDesc)
        )
    }

    public var description: String {
        PJLink.identifier + self.class.rawValue + self.command.rawValue + PJLink.separatorResponse + self.code.rawValue
    }
}
