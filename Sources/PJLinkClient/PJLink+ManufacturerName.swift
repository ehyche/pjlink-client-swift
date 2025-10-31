//
//  PJLink+ManufacturerName.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct ManufacturerName: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.ManufacturerName {

    public static let mock = Self(value: "Mock Manufacturer Name")
}
