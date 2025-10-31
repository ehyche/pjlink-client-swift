//
//  PJLink+ModelNumber.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct ModelNumber: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.ModelNumber {

    public static let mock = Self(value: "Mock Model Number")
}
