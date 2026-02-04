//
//  PJLink+MacAddress.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/2/26.
//

extension PJLink {

    public struct MacAddress: Equatable, Sendable {
        private var address0: UInt8
        private var address1: UInt8
        private var address2: UInt8
        private var address3: UInt8
        private var address4: UInt8
        private var address5: UInt8
    }
}

extension PJLink.MacAddress: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let components = try description
            .split(separator: ":")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .map { try $0.map { try PJLink.HexCharacter($0) } }
        guard components.count == 6, components.allSatisfy({ $0.count == 2 }) else {
            throw PJLink.Error.macAddressIllegalFormat(description)
        }
        let hexBytes = components.map { PJLink.HexByte(upper: $0[0], lower: $0[1]) }
        address0 = hexBytes[0].uint8Value
        address1 = hexBytes[1].uint8Value
        address2 = hexBytes[2].uint8Value
        address3 = hexBytes[3].uint8Value
        address4 = hexBytes[4].uint8Value
        address5 = hexBytes[5].uint8Value
    }

    public var description: String {
        String(format: "%02X:%02X:%02X:%02X:%02X:%02X", address0, address1, address2, address3, address4, address5)
    }
}

extension PJLink.MacAddress {

    // "DE:AD:BE:EF:FA:DE" -> "DEADBEEFFADE"
    public static let mock = Self(
        address0: 222,
        address1: 173,
        address2: 190,
        address3: 239,
        address4: 250,
        address5: 222
    )
}
