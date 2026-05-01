//
//  PJLink+PingSweepProjectorDiscovery.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 4/24/26.
//

import ConcurrencyExtras
import Foundation
import Network
import PJLinkCommon
import PJLinkBroadcastUDP
import os

extension PJLink {

    public struct PingSweepProjectorDiscovery: Sendable {

        public enum Error: Swift.Error {
            case noHostsToSweep
            case cancelled
        }

        public struct Projector: Equatable, Sendable {
            public let host: NWEndpoint.Host
        }

        public enum DiscoveryEvent: Equatable, Sendable {
            case projectorFound(Projector)
            case progressUpdate(Double)
        }

        public let outputStream: AsyncThrowingStream<DiscoveryEvent, Swift.Error>
        private let continuation: AsyncThrowingStream<DiscoveryEvent, Swift.Error>.Continuation
        private let task: Task<Void, Swift.Error>

        public init(hosts: [NWEndpoint.Host]) throws {
            let logger = Logger(sub: .client, cat: .discovery)
            logger.info("PingSweepProjectorDiscovery(hosts: \(hosts.count) hosts)")
            guard !hosts.isEmpty else {
                throw Error.noHostsToSweep
            }
            let hostCount = Double(hosts.count)
            let checkedCount: LockIsolated<Int> = .init(0)
            let (stream, cont) = AsyncThrowingStream.makeStream(of: DiscoveryEvent.self)
            self.outputStream = stream
            self.continuation = cont
            let hostGroups = Self.subdivideHosts(hosts)
            logger.info("Divided hosts into \(hostGroups.count) groups")
            self.task = Task {
                try Task.checkCancellation()
                await withTaskGroup { group in
                    for hostGroup in hostGroups {
                        group.addTask {
                            guard !Task.isCancelled else { return }
                            for host in hostGroup {
                                guard !Task.isCancelled else { return }
                                logger.debug("Pinging host at \(host.debugDescription)")
                                let isPresent = await PJLink.Client.isProjectorPresent(at: host)
                                if isPresent {
                                    logger.info("Found projector at \(host.debugDescription, privacy: .public)")
                                    cont.yield(.projectorFound(.init(host: host)))
                                }
                                checkedCount.withValue { mutableCount in
                                    mutableCount += 1
                                    let progress = Double(mutableCount) / hostCount
                                    cont.yield(.progressUpdate(progress))
                                }
                            }
                        }
                    }
                }
                cont.finish()
            }
        }

        public func cancel() {
            continuation.finish(throwing: Error.cancelled)
            task.cancel()
        }

        public static func hostsToPing(
            address: Network.IPv4Address,
            netmask: Network.IPv4Address,
            broadcast: Network.IPv4Address? = nil,
            gateway: Network.IPv4Address? = nil
        ) throws -> [NWEndpoint.Host] {
            let subnetAddresses = try IPv4AddressData.subnetRange(
                address: .init(address),
                netmask: .init(netmask)
            )
            var addresses = Set<IPv4AddressData>()
            for address in subnetAddresses {
                addresses.insert(address)
            }
            // Remove our own address
            addresses.remove(address.asAddressData)
            // Remove the broadcast address (if provided)
            if let broadcast {
                addresses.remove(broadcast.asAddressData)
            }
            // Remove the gateway address (if provided)
            if let gateway {
                addresses.remove(gateway.asAddressData)
            }
            return addresses
                .sorted()
                .compactMap(\.asIPv4Address)
                .map { NWEndpoint.Host.ipv4($0) }
        }

        private static func subdivideHosts(_ hosts: [NWEndpoint.Host]) -> [[NWEndpoint.Host]] {
            let numGroups = ProcessInfo.processInfo.processorCount
            let groupSize = (hosts.count + numGroups - 1) / numGroups
            return stride(from: 0, to: hosts.count, by: groupSize).map {
                Array(hosts[$0..<Swift.min($0 + groupSize, hosts.count)])
            }
        }
    }
}

extension Network.IPv4Address {

    var asAddressData: IPv4AddressData { .init(self) }
}
