//
//  PJLink+NetworkInterface.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 4/24/26.
//

import Network
import PJLinkCommon

extension PJLink.IPAddressDiscovery.NetworkInterface {

    var allHosts: Set<NWEndpoint.Host> {
        return []
    }

    public struct AddressTriple<T> where T: Network.IPAddress {
        public let address: T
        public let netmask: T
        public let broadcast: T
    }

    public var v4Triple: AddressTriple<IPv4Address>? {
        guard
            let address = self.address.ipv4Address,
            let netmask = self.netmask?.ipv4Address,
            let broadcast = self.broadcast?.ipv4Address
        else {
            return nil
        }
        return AddressTriple(address: address, netmask: netmask, broadcast: broadcast)
    }

    public var v6Triple: AddressTriple<IPv6Address>? {
        guard
            let address = self.address.ipv6Address,
            let netmask = self.netmask?.ipv6Address,
            let broadcast = self.broadcast?.ipv6Address
        else {
            return nil
        }
        return AddressTriple(address: address, netmask: netmask, broadcast: broadcast)
    }
}

extension PJLink.IPAddressDiscovery.IPAddress {

    public var ipv4Address: IPv4Address? {
        switch self {
        case .v4(let str): IPv4Address(str)
        case .v6: nil
        }
    }

    public var ipv6Address: IPv6Address? {
        switch self {
        case .v4: nil
        case .v6(let str): IPv6Address(str)
        }
    }
}
