//
//  PJLink+OnOff.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum OnOff: String, CaseIterable, Sendable, Codable {
        case off = "0"
        case on = "1"
    }
}

extension PJLink.OnOff: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let onOff = PJLink.OnOff(rawValue: description) else {
            throw PJLink.Error.invalidOnOff(description)
        }
        self = onOff
    }

    public var description: String { rawValue }
}
