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
