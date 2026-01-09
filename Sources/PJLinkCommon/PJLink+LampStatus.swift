//
//  PJLink+LampStatus.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public struct LampStatus: Equatable, Sendable, Codable {
        var usageTime: Int
        var state: OnOff
    }

    public struct LampsStatus: Equatable, Sendable, Codable {
        var lampStatus: [LampStatus]
    }
}

extension PJLink.LampsStatus: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let components = description.split(separator: " ").map(String.init)
        guard components.count % 2 == 0 else {
            throw PJLink.Error.invalidLampStatusCount(components.count)
        }
        var lampStatuses: [PJLink.LampStatus] = []
        try stride(from: 0, to: components.count, by: 2).forEach { index in
            guard let usageTime = Int(components[index]) else {
                throw PJLink.Error.invalidLampUsageTime(components[index])
            }
            guard usageTime >= Self.lampUsageMin, usageTime <= Self.lampUsageMax else {
                throw PJLink.Error.lampUsageTimeOutOfRange(usageTime)
            }
            guard let onOff = PJLink.OnOff(rawValue: components[index + 1]) else {
                throw PJLink.Error.invalidLampOnOff(components[index + 1])
            }
            lampStatuses.append(.init(usageTime: usageTime, state: onOff))
        }
        self.lampStatus = lampStatuses
    }

    public var description: String {
        lampStatus
            .map(\.description)
            .joined(separator: " ")
    }

    private static let lampUsageMin = 0
    private static let lampUsageMax = 99_999
}

extension PJLink.LampStatus: CustomStringConvertible {

    public var description: String {
        "\(usageTime) \(state.rawValue)"
    }
}

extension PJLink.LampStatus {

    public static let mock1: Self = .init(usageTime: 12345, state: .off)
    public static let mock2: Self = .init(usageTime: 6789, state: .on)
    public static let mock3: Self = .init(usageTime: 42, state: .off)
}

extension PJLink.LampsStatus {

    public static let mock: Self = .init(lampStatus: [.mock1, .mock2, .mock3])
}
