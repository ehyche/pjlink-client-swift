//
//  PJLink+SearchServer.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 3/9/26.
//

import Network
import os
import PJLinkCommon

extension PJLink {

    public struct SearchServer: Sendable {
        private let macAddress: MacAddress
        private let logger: Logger
        private let udpListener: UDPListener

        private struct SearchPacket: Equatable, Sendable {
            public let host: NWEndpoint.Host
        }

        public init(macAddress: MacAddress) throws {
            self.macAddress = macAddress
            self.logger = Logger(sub: .server, cat: .searchListener)
            udpListener = try UDPListener(port: .pjlink)
        }

        public func run() async throws {
            let searchRequestStream = udpListener.outputStream.compactMap(Self.searchPacket(from:))
            for try await searchRequest in searchRequestStream {
                logger.info("RECV: Search request from \(searchRequest.host.debugDescription, privacy: .public)")
                try Task.checkCancellation()
                do {
                    try await sendSearchAck(to: searchRequest.host)
                    logger.info("SEND: Sent ACKN to \(searchRequest.host.debugDescription, privacy: .public)")
                } catch {
                    logger.error("Error sending ACKN to \(searchRequest.host.debugDescription, privacy: .public)")
                }
            }
        }

        public func cancel() {
            udpListener.cancel()
        }

        private static func searchPacket(from udpPacket: UDPListener.Output) -> SearchPacket? {
            guard
                let host = udpPacket.host,
                let utf8 = try? udpPacket.data.toUTF8String(),
                let search = try? PJLink.Search(utf8),
                search == .request
            else {
                return nil
            }
            return .init(host: host)
        }

        private func sendSearchAck(to host: NWEndpoint.Host) async throws {
            let udpConnection = NetworkConnection(to: .hostPort(host: host, port: .pjlink)) {
                UDP()
            }
            let searchResponse = PJLink.Search.response(macAddress)
            try await udpConnection.send(searchResponse.description.crTerminatedData)
        }
    }
}
