//
//  PJLink+ProjectorDiscovery.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/23/26.
//

import ConcurrencyExtras
import Foundation
import Network
import PJLinkCommon
import PJLinkBroadcastUDP
import os

extension PJLink {

    public struct ProjectorDiscovery: Sendable {
        private let udpListener: UDPListener
        private let asyncTimer: AsyncTimer
        public let outputStream: AsyncThrowingStream<Projector, Swift.Error>

        public struct Projector: Equatable, Sendable {
            public let host: NWEndpoint.Host?
            public let macAddress: MacAddress
        }

        public init(broadcastHost: String, duration: Duration) throws {
            let logger = Logger(sub: .client, cat: .discovery)
            let listener = try UDPListener(port: .pjlink)
            self.asyncTimer = AsyncTimer(every: duration, count: 1) {
                logger.debug("Timer expired, cancelling discovery")
                listener.cancel()
            }
            self.udpListener = listener
            self.outputStream = udpListener
                .outputStream
                .compactMap(Self.outputToProjector)
                .eraseToThrowingStream()
            // Send the broadcast packet
            let dataString = PJLink.Search.request.description
            logger.debug("Sending broadcast UDP packet: \(dataString, privacy: .public)")
            _ = try PJLink.BroadcastUDP.sendBroadcastUDP(
                data: dataString.crTerminated,
                broadcastHost: broadcastHost,
                broadcastPort: PJLink.searchBroadcastUDPPort
            )
        }

        public func cancel() {
            let logger = Logger(sub: .client, cat: .discovery)
            logger.debug("cancel()")
            udpListener.cancel()
            asyncTimer.cancel()
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
