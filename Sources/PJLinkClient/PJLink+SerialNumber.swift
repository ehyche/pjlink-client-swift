//
//  PJLink+SerialNumber.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct SerialNumber: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.SerialNumber {

    public static let mock = Self(value: "Mock Serial Number")
}
