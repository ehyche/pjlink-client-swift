//
//  PJLink+Freeze.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum Freeze: String, CaseIterable, Equatable, Sendable {
        case stop = "0"
        case start = "1"
    }
}

extension PJLink.Freeze: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let freeze = PJLink.Freeze(rawValue: description) else {
            throw PJLink.Error.invalidFreeze(description)
        }
        self = freeze
    }

    public var description: String { rawValue }
}
