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
