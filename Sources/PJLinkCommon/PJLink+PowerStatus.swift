//
//  PJLink+PowerStatus.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum PowerStatus: String, CaseIterable, Equatable, Sendable, Codable {
        case standby = "0"
        case lampOn = "1"
        case cooling = "2"
        case warmUp = "3"
    }
}

extension PJLink.PowerStatus: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let powerStatus = PJLink.PowerStatus(rawValue: description) else {
            throw PJLink.Error.invalidPowerStatus(description)
        }
        self = powerStatus
    }

    public var description: String { rawValue }
}
