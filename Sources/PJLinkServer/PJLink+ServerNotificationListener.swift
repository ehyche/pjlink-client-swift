//
//  PJLink+ServerNotificationListener.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/3/26.
//

import Network
import os
import PJLinkCommon

extension PJLink {

    public final class ServerNotificationListener {
        private let networkListener: NetworkListener<UDP>

        public init() throws {
            let logger = Logger(sub: .server, cat: .listener)
            logger.debug("[NotificationListener] init()")
            let listener = try NetworkListener(
                using: .parameters {
                    UDP()
                }
                .localPort(4352)
            )
            listener.onServiceRegistrationUpdate { listener, change in
                switch change {
                case .add(let endpoint):
                    logger.debug("[NotificationListener] Endpoint Added: \(endpoint.debugDescription, privacy: .public)")
                case .remove(let endpoint):
                    logger.debug("[NotificationListener] Endpoint Removed: \(endpoint.debugDescription, privacy: .public)")
                @unknown default:
                    break
                }
            }
            listener.onStateUpdate { listener, state in
                logger.debug("[NotificationListener] State Update: \(state.name, privacy: .public)")
            }
            networkListener = listener
        }

        public func run() async throws -> Bool {
            let logger = Logger(sub: .server, cat: .listener)
            logger.debug("[NotificationListener] run()")
            try await networkListener.run { connection in
                logger.info("[NotificationListener] New Connection: \(connection.id) remoteEndpoint=\(String(describing: connection.remoteEndpoint))")
                let data = try await connection.receive().content
                let notificationUTF8 = try data.toUTF8String()
                logger.info("[NotificationListener] RECV \"\(notificationUTF8, privacy: .public)\"")
            }
            return true
        }
    }
}

private extension NetworkListener.State {

    var name: String {
        switch self {
        case .setup: "Setup"
        case .waiting(let error): "Waiting(\(error))"
        case .ready: "Ready"
        case .failed(let error): "Failed(\(error))"
        case .cancelled: "Cancelled"
        @unknown default: "Unknown"
        }
    }
}
