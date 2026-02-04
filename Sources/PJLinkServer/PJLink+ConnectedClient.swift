//
//  PJLink+ConnectedClient.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/3/26.
//

import Foundation
import Network
import os
import PJLinkCommon

extension PJLink {

    public final class ConnectedClient: Sendable {
        private let logger = Logger(sub: .server, cat: .notification)
        private let host: NWEndpoint.Host
        private let connection: NetworkConnection<UDP>

        public init(host: NWEndpoint.Host) {
            logger.debug("[ConnectedClient(\(host.debugDescription, privacy: .public))] init")
            self.host = host
            self.connection = NetworkConnection(to: .hostPort(host: host, port: 4352)) {
                UDP()
            }
        }

        public func sendNotification(_ notification: PJLink.Notification) async throws {
            logger.info("[ConnectedClient(\(self.host.debugDescription, privacy: .public))] Sending notification: \"\(notification.description, privacy: .public)\"")
            try await connection.send(Data(notification.description.crTerminatedData))
        }
    }
}
