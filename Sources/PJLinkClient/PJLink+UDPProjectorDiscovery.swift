//
//  PJLink+UDPProjectorDiscovery.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/23/26.
//

import AsyncAlgorithms
import ConcurrencyExtras
import Foundation
import Network
import PJLinkCommon
import PJLinkBroadcastUDP
import os

extension PJLink {

    public struct UDPProjectorDiscovery: Sendable {
        private let udpListener: UDPListener
        public let outputStream: AsyncThrowingStream<DiscoveryEvent, Swift.Error>

        public enum DiscoveryEvent: Equatable, Sendable {
            case progressUpdate(Double)
            case projectorDiscovered(Projector)
        }

        public struct Projector: Equatable, Sendable {
            public let host: NWEndpoint.Host?
            public let macAddress: MacAddress
        }

        public init(broadcastHost: String, duration: Duration, progressUpdateCount: Int = 100) throws {
            let logger = Logger(sub: .client, cat: .discovery)
            let listener = try UDPListener(port: .pjlink)
            let startingInstant = SuspendingClock.Instant.now
            let indexStream = Array(1...progressUpdateCount).async
            let timerStream = AsyncTimerSequence
                .repeating(every: duration / Double(progressUpdateCount))
                .prefix(progressUpdateCount)
            let progressStream = zip(indexStream, timerStream)
                .map {
                    if $0.0 >= progressUpdateCount {
                        logger.debug("UDPProjectorDiscovery: Duration of \(duration) expired, cancelling discovery")
                        listener.cancel()
                    }
                    let progress = ($0.1 - startingInstant) / duration
                    let progressClamped = min(max(progress, 0.0), 1.0)
                    return DiscoveryEvent.progressUpdate(progressClamped)
                }
            let projectorStream = listener
                .outputStream
                .compactMap(Self.outputToProjector)
                .map(DiscoveryEvent.projectorDiscovered)
            self.outputStream = merge(progressStream, projectorStream)
                .eraseToThrowingStream()
            self.udpListener = listener
            // Send the broadcast packet
            let dataString = PJLink.Search.request.description
            logger.debug("UDPProjectorDiscovery: Sending broadcast UDP packet: \(dataString, privacy: .public)")
            _ = try PJLink.BroadcastUDP.sendBroadcastUDP(
                data: dataString.crTerminated,
                broadcastHost: broadcastHost,
                broadcastPort: PJLink.searchBroadcastUDPPort
            )
        }

        public func cancel() {
            let logger = Logger(sub: .client, cat: .discovery)
            logger.debug("UDPProjectorDiscovery.cancel()")
            udpListener.cancel()
        }

        private static func outputToProjector(_ output: PJLink.UDPListener.Output) -> Projector? {
            guard
                let utf8String = output.data.utf8StringWithCRStripped,
                let search = try? PJLink.Search(utf8String)
            else {
                return nil
            }
            switch search {
            case .request:
                return nil
            case .response(let macAddress):
                return .init(host: output.host, macAddress: macAddress)
            }
        }
    }
}
