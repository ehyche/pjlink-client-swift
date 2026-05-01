//
//  IPv4AddressData.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 5/1/26.
//

import Foundation
import Network

public struct IPv4AddressData {
    private let address: UInt32

    public init(_ data: Data) throws {
        guard data.count == 4 else {
            throw Error.invalidDataLength(data.count)
        }
        address = UInt32(data)
    }

    public init(_ ipv4Address: Network.IPv4Address) {
        address = UInt32(ipv4Address.rawValue)
    }

    public var asIPv4Address: Network.IPv4Address? {
        .init(address.asBigEndianData)
    }

    public init(_ address: String) throws {
        let parts = address
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(UInt8.init)
        guard parts.count == 4 else {
            throw Error.invalidAddressString(address)
        }
        try self.init(Data(parts))
    }

    public init(_ address: UInt32) {
        self.address = address
    }

    public enum Error: Swift.Error {
        case invalidDataLength(Int)
        case invalidMask(UInt32)
        case invalidAddressString(String)
    }

    public var asUInt32: UInt32 { address }

    public var asString: String {
        address.asBigEndianData.map(String.init).joined(separator: ".")
    }

    public static func subnetRange(address: Self, netmask: Self) throws -> ClosedRange<Self> {
        let maskedRange = try netmask.asUInt32.maskedRange
        let netmaskUInt32 = netmask.asUInt32
        let lowerBoundUInt32 = address.asUInt32 & netmaskUInt32
        let upperBoundUInt32 = (lowerBoundUInt32 + maskedRange.upperBound) & netmaskUInt32
        return Self(lowerBoundUInt32)...Self(upperBoundUInt32)
    }
}

extension IPv4AddressData: Equatable { }

extension IPv4AddressData: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.address < rhs.address
    }
}

extension IPv4AddressData: Hashable { }

extension IPv4AddressData: CustomStringConvertible {

    public var description: String { asString }
}

extension IPv4AddressData: CustomDebugStringConvertible {

    public var debugDescription: String { asString }
}

extension IPv4AddressData: Strideable {
    public typealias Stride = Int32

    public func advanced(by n: Stride) -> IPv4AddressData {
        .init(UInt32(Stride(address) + n))
    }


    public func distance(to other: IPv4AddressData) -> Stride {
        Stride(other.address) - Stride(address)
    }
}

private extension UInt32 {

    init(_ data: Data) {
        let count = data.count
        let byte0 = count > 0 ? (UInt32(data[0]) << 24) : 0
        let byte1 = count > 1 ? (UInt32(data[1]) << 16) : 0
        let byte2 = count > 2 ? (UInt32(data[2]) <<  8) : 0
        let byte3 = count > 3 ?  UInt32(data[3])        : 0
        self = byte0 | byte1 | byte2 | byte3
    }

    var asBigEndianData: Data {
        var data = Data()
        data.append(UInt8((self & 0xff000000) >> 24))
        data.append(UInt8((self & 0x00ff0000) >> 16))
        data.append(UInt8((self & 0x0000ff00) >>  8))
        data.append(UInt8( self & 0x000000ff))
        return data
    }

    var maskedRange: ClosedRange<Self> {
        get throws {
            guard leftSideMask else {
                throw IPv4AddressData.Error.invalidMask(self)
            }
            let maxValue = ~self
            return 0...maxValue
        }
    }

    var leftSideMask: Bool {
        Self.leftSideMasks.contains(self)
    }

    /// This function produces a set containing the following `UInt32`s:
    /// `0b11111111111111111111111111111110`,
    /// `0b11111111111111111111111111111100`,
    /// `0b11111111111111111111111111111000`,
    /// `0b11111111111111111111111111110000`,
    /// `0b11111111111111111111111111100000`,
    /// and so on...
    static let leftSideMasks: Set<UInt32> = {
        var masks = Set<UInt32>()
        var current: UInt32 = 0xffffffff
        for _ in 0..<32 {
            current <<= 1
            masks.insert(current)
        }
        return masks
    }()
}
