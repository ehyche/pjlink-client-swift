//
//  PJLink+Volume.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/21/26.
//

extension PJLink {

    public struct Volume: Codable, Sendable {
        public var value: Int

        public init(value: Int = Self.initialVolume) {
            self.value = max(min(value, Self.maxVolume), Self.minVolume)
        }

        public func applyingAdjustment(_ volumeAdjustment: PJLink.VolumeAdjustment) -> Self {
            switch volumeAdjustment {
            case .decrease:
                Self(value: value - 1)
            case .increase:
                Self(value: value + 1)
            }
        }

        public static let minVolume = 0
        public static let maxVolume = 10
        public static let initialVolume = 5
    }
}
