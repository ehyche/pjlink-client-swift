//
//  PJLink+OtherInformation.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct OtherInformation: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.OtherInformation {

    public static let mock = Self(value: "Mock Other Information")
}
