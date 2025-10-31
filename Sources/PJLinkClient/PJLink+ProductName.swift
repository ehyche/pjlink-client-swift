//
//  PJLink+ProductName.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct ProductName: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.ProductName {

    public static let mock = Self(value: "Mock Product Name")
}
