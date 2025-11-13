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
        guard description.count <= Self.maxLength else {
            throw PJLink.Error.projectorNameExceedsMaximumLength(description.count)
        }
        self.init(value: description)
    }

    public var description: String { value }

    private static let maxLength = 64
}
