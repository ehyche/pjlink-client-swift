//
//  PJLink+ProductName.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct ProductName: Equatable, Sendable, Codable {
        public var value: String
    }
}

extension PJLink.ProductName {

    public static let mock = Self(value: "Mock Product Name")
}

extension PJLink.ProductName: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let utf8 = Array(description.utf8)
        guard utf8.count <= Self.maxLength else {
            throw PJLink.Error.stringExceedsMaximumLength(utf8.count, Self.maxLength)
        }
        if let firstInvalidIndex = utf8.firstIndex(where: { !Self.validRange.contains($0) }) {
            throw PJLink.Error.characterOutOfValidBounds(utf8[firstInvalidIndex], Self.validRange)
        }
        self.init(value: description)
    }

    public var description: String { value }

    private static let maxLength = 32
    private static let validRange: ClosedRange<UInt8> = 0x20...0x7E
}
