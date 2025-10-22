//
//  PJLink+LampStatus.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public struct LampStatus: Equatable {
        var usageTime: Int
        var state: OnOff
    }

    public struct LampsStatus: Equatable {
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
}

extension PJLink.LampStatus: CustomStringConvertible {

    public var description: String {
        "\(usageTime) \(state.rawValue)"
    }
}
