//
//  PJLink+FilterUsageTime.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct FilterUsageTime: Equatable, Sendable, Codable {
        public var value: Int
    }
}

extension PJLink.FilterUsageTime: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        guard let filterUsageTime = Int(description) else {
            throw PJLink.Error.invalidFilterUsageTime(description)
        }
        guard filterUsageTime >= Self.timeMin, filterUsageTime <= Self.timeMax else {
            throw PJLink.Error.filterUsageTimeOutOfRange(filterUsageTime)
        }
        value = filterUsageTime
    }

    public var description: String {
        "\(value)"
    }

    private static let timeMin = 0
    private static let timeMax = 99_999
}

extension PJLink.FilterUsageTime {

    public static let mock = Self(value: 12345)
}
