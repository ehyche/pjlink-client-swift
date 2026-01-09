//
//  PJLink+Class.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

extension PJLink {
    public enum Class: String, CaseIterable, Sendable {
        case one = "1"
        case two = "2"
    }
}

extension PJLink.Class: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let pjlinkClass = PJLink.Class(rawValue: description) else {
            throw PJLink.Error.invalidClass(description)
        }
        self = pjlinkClass
    }

    public var description: String { rawValue }
}
