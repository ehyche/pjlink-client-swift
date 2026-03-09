//
//  PJLink+IPAddressDiscovery.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 3/4/26.
//

import NIOCore
import PJLinkCommon

extension PJLink {

    public enum IPAddressDiscovery {

        public enum IPAddress: Equatable, Sendable {
            case v4(String)
            case v6(String)
        }

        public struct NetworkInterface: Equatable, Sendable {
            public let name: String
            public let address: IPAddress
            public let netmask: IPAddress?
            public let broadcast: IPAddress?
            public let multicastSupported: Bool
            public let interfaceIndex: Int
        }

        public static func enumerateInterfaces() throws -> [NetworkInterface] {
            try System.enumerateDevices().compactMap(\.asNetworkInterface)
        }

        public static func getBroadcastAddress() throws -> IPAddress? {
            try enumerateInterfaces().compactMap(\.broadcast).first
        }
    }
}

private extension SocketAddress {

    var asIPAddress: PJLink.IPAddressDiscovery.IPAddress? {
        switch self {
        case .v4(let ipV4Address): .v4(ipV4Address.host)
        case .v6(let ipV6Address): .v6(ipV6Address.host)
        case .unixDomainSocket: nil
        }
    }
}

private extension NIONetworkDevice {

    var asNetworkInterface: PJLink.IPAddressDiscovery.NetworkInterface? {
        guard let address = self.address?.asIPAddress else { return nil }
        return .init(
            name: name,
            address: address,
            netmask: netmask?.asIPAddress,
            broadcast: broadcastAddress?.asIPAddress,
            multicastSupported: multicastSupported,
            interfaceIndex: interfaceIndex
        )
    }
}

extension PJLink.IPAddressDiscovery.IPAddress: CustomStringConvertible {

    public var description: String {
        switch self {
        case .v4(let address): "v4(\(address))"
        case .v6(let address): "v6(\(address))"
        }
    }
}

extension PJLink.IPAddressDiscovery.NetworkInterface: CustomStringConvertible {

    public var description: String {
        "(name=\(name),address=\(address),netmask=\(String(describing: netmask)),broadcast=\(String(describing: broadcast)),multicastSupported=\(multicastSupported),interfaceIndex=\(interfaceIndex))"
    }
}

extension PJLink.IPAddressDiscovery.IPAddress {

    public var host: String {
        switch self {
        case .v4(let address): address
        case .v6(let address): address
        }
    }
}
