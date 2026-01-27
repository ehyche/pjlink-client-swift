//
//  PJLink+VolumeAdjustment.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum VolumeAdjustment: String, CaseIterable, Sendable {
        case decrease = "0"
        case increase = "1"
    }
}

extension PJLink.VolumeAdjustment {

    public var displayName: String {
        switch self {
        case .decrease: "Decrease"
        case .increase: "Increase"
        }
    }
}

extension PJLink.VolumeAdjustment: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let volumeAdjustment = PJLink.VolumeAdjustment(rawValue: description) else {
            throw PJLink.Error.invalidVolume(description)
        }
        self = volumeAdjustment
    }

    public var description: String { rawValue }
}
