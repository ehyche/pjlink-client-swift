//
//  PJLink+Server.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/9/26.
//

import ConcurrencyExtras
import Foundation
import Network
import os
import PJLinkCommon

extension PJLink {

    public final class Server {
        private let state: LockIsolated<PJLink.State>
        private let authConfig: AuthConfig
        private let serverConnections = LockIsolated<[ServerConnection]>([])

        public init(config: ServerConfig) {
            self.state = .init(config.initialState)
            self.authConfig = config.auth
        }

        public func run() async throws -> Bool {
            let logger = Logger(cat: .listener)
            let listener = try NetworkListener(
                using: .parameters {
                    TCP()
                }
                .localPort(4352)
            )
            listener.onServiceRegistrationUpdate { listener, change in
                switch change {
                case .add(let endpoint):
                    logger.debug("[Listener] Endpoint Added: \(endpoint.debugDescription)")
                case .remove(let endpoint):
                    logger.debug("[Listener] Endpoint Removed: \(endpoint.debugDescription)")
                @unknown default:
                    break
                }
            }
            listener.onStateUpdate { listener, state in
                switch state {
                case .setup:
                    logger.debug("[Listener] State Update: setup")
                case .waiting(let error):
                    logger.debug("[Listener] State Update: waiting(\(error)")
                case .ready:
                    logger.debug("[Listener] State Update: ready")
                case .failed(let error):
                    logger.error("[Listener] State Update: failed(\(error)")
                case .cancelled:
                    logger.debug("[Listener] State Update: cancelled")
                @unknown default:
                    break
                }
            }
            try await listener.run { [serverConnections = self.serverConnections, state = self.state, authConfig = self.authConfig] connection in
                logger.info("[Listener] New Connection: \(connection.id)")
                let serverConnection = ServerConnection(connection: connection, state: state, authConfig: authConfig) { serverConn in
                    logger.info("[Listener] Connection \(connection.id) Terminated")
                    serverConnections.withValue {
                        $0.removeAll(where: { $0 === serverConn })
                    }
                }
                serverConnections.withValue {
                    $0.append(serverConnection)
                }
                do {
                    try await serverConnection.run()
                } catch {
                    logger.error("[Listener] Uncaught Error in ServerConnection.run(): \(error)")
                }
            }
            return true
        }
    }

    public struct ServerConfig: Sendable, Codable {
        public let initialState: PJLink.State
        public let auth: AuthConfig
    }

    public struct AuthConfig: Sendable, Codable {
        public let password: String?
    }
}

extension PJLink.AuthConfig {

    public static let mock = Self(password: "Mock Password")
}

extension PJLink.ServerConfig {

    public static let mock: Self = .init(initialState: .mockClass2, auth: .mock)
}
