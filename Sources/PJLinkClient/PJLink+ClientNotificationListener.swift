//
//  PJLink+ClientNotificationListener.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/2/26.
//

import Network
import os
import PJLinkCommon

extension PJLink {

    public final class ClientNotificationListener {
        public typealias OnNotification = @Sendable (NWEndpoint.Host?, PJLink.Notification) -> Void

        let onNotification: OnNotification
        let networkListener: NetworkListener<UDP>

        public init(onNotification: @escaping OnNotification) throws {
            self.onNotification = onNotification
            let logger = Logger(sub: .client, cat: .listener)
            let listener = try NetworkListener(
                using: .parameters {
                    UDP()
                }
                .localPort(4352)
            )
            listener.onServiceRegistrationUpdate { listener, change in
                switch change {
                case .add(let endpoint):
                    logger.debug("[Listener] Endpoint Added: \(endpoint.debugDescription, privacy: .public)")
                case .remove(let endpoint):
                    logger.debug("[Listener] Endpoint Removed: \(endpoint.debugDescription, privacy: .public)")
                @unknown default:
                    break
                }
            }
            listener.onStateUpdate { listener, state in
                logger.debug("[Listener] State Update: \(state.name, privacy: .public)")
            }
            networkListener = listener
        }

        public func run() async throws -> Bool {
            let logger = Logger(sub: .client, cat: .listener)
            logger.debug("[NotificationListener] run() enter")
            try await networkListener.run { [onNotify = self.onNotification] connection in
                logger.debug("[NotificationListener] New Connection: \(connection.id) remoteEndpoint=\(String(describing: connection.remoteEndpoint))")
                let data = try await connection.receive().content
                do {
                    let notificationUTF8 = try data.toUTF8String()
                    let notification = try PJLink.Notification(notificationUTF8)
                    logger.info("[NotificationListener] RECV \"\(notification)\" from \"\(String(describing: connection.remoteEndpoint?.host))\"")
                    onNotify(connection.remoteEndpoint?.host, notification)
                } catch {
                    logger.error("[NotificationListener] Error parsing notification: \(error)")
                }
            }
            logger.debug("[NotificationListener] run() exit")
            return true
        }
    }
}

private extension NWEndpoint {

    var host: NWEndpoint.Host? {
        switch self {
        case .hostPort(let host, _): host
        default: nil
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
