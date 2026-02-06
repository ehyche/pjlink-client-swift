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
        private let serverConnections = LockIsolated<[NWEndpoint.Host: [ServerConnection]]>([:])
        private let connectedClients = LockIsolated<[NWEndpoint.Host: ConnectedClient]>([:])

        public init(config: ServerConfig) {
            self.state = .init(config.initialState)
            self.authConfig = config.auth
        }

        public func run() async throws -> Bool {
            let logger = Logger(sub: .server, cat: .listener)
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
                logger.debug("[Listener] State Update: \(state.name, privacy: .public)")
            }
            try await listener.run { [
                hostMap = self.serverConnections,
                connectedClientMap = self.connectedClients,
                state = self.state,
                authConfig = self.authConfig
            ] connection in
                logger.info("[Listener] New Connection \(connection.id) from \"\(String(describing: connection.remoteEndpoint))\"")
                guard let host = connection.remoteEndpoint?.host else {
                    logger.error("[Listener] Could not obtain host for \(connection.id) - early exit")
                    return
                }
                let serverConnection = ServerConnection(
                    connection: connection,
                    state: state,
                    authConfig: authConfig,
                    onTerminated: { serverConn in
                        logger.info("[Listener] Connection \(connection.id) onTerminated")
                        hostMap.withValue { mutableHostMap in
                            var connectionsForHost = mutableHostMap[host] ?? []
                            connectionsForHost.removeAll(where: { $0 === serverConn })
                            mutableHostMap[host] = connectionsForHost
                        }
                        // If we have no more connections for this host,
                        // then remove the ConnectedClient from the map
                        let connectionCountForHost = hostMap.value[host]?.count ?? 0
                        if connectionCountForHost == 0 {
                            connectedClientMap.withValue { mutableConnectedClientMap in
                                mutableConnectedClientMap[host] = nil
                            }
                        }
                    },
                    onSendNotification: { [connectedClients = connectedClientMap.value.values] notification in
                        logger.info("[Listener] Connection \(connection.id) onSendNotification(\(notification))")
                        await withThrowingTaskGroup { group in
                            connectedClients.forEach { connectedClient in
                                group.addTask {
                                    try await connectedClient.sendNotification(notification)
                                }
                            }
                        }
                    },
                    onPowerStatusChange: { oldPowerStatus, newPowerStatus in

                    }
                )
                hostMap.withValue {
                    $0[host, default: []].append(serverConnection)
                }
                connectedClientMap.withValue {
                    guard $0[host] == nil else { return }
                    $0[host] = ConnectedClient(host: host)
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
