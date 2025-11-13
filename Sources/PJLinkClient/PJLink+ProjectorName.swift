//
//  PJLink+ProjectorName.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct ProjectorName: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.ProjectorName {

    public static let mock = Self(value: "Mock Projector Name")
}

extension PJLink.ProjectorName: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let utf8 = Array(description.utf8)
        guard utf8.count <= Self.maxLength else {
            throw PJLink.Error.projectorNameExceedsMaximumLength(description.count)
        }
        if let firstInvalidIndex = utf8.firstIndex(where: { $0 < Self.minCodeUnitValue }) {
            throw PJLink.Error.projectorNameContainsInvalidASCIIValue(utf8[firstInvalidIndex])
        }
        self.init(value: description)
    }

    public var description: String { value }

    private static let maxLength = 64
    private static let minCodeUnitValue: UInt8 = 32
}
