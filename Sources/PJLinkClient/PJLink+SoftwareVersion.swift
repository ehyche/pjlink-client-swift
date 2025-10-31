//
//  PJLink+SoftwareVersion.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct SoftwareVersion: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.SoftwareVersion {

    public static let mock = Self(value: "Mock Software Version")
}
