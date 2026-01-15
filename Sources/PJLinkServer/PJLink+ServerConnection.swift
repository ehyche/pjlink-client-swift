//
//  PJLink+ServerConnection.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/14/26.
//

import Network
import PJLinkCommon

extension PJLink {

    public final class ServerConnection: Sendable {
        public typealias OnTerminated = @Sendable (ServerConnection) -> Void

        private let connection: NetworkConnection<TCP>
        private let onTerminated: OnTerminated

        public init(connection: NetworkConnection<TCP>, onTerminated: @escaping OnTerminated) {
            self.connection = connection
            self.onTerminated = onTerminated
        }

        public func run() async throws {
            connection.onBetterPathUpdate { connection, newValue in
                print("ServerConnection onBetterPathUpdate(\(connection), \(newValue))")
            }
            connection.onPathUpdate { connection, newPath in
                print("ServerConnection onPathUpdate(\(connection), \(newPath))")
            }
            connection.onViabilityUpdate { connection, newViable in
                print("ServerConnection onViabilityUpdate(\(connection), \(newViable))")
            }
            connection.onStateUpdate { connection, state in
                print("ServerConnection onStateUpdate(\(connection), \(state))")
                switch state {
                case .failed:
                    self.onTerminated(self)
                case .cancelled:
                    self.onTerminated(self)
                default:
                    break
                }
            }

            while !connection.state.isFinished {
                let data = try await connection.receive(atMost: 1024).content
                let dataString = String(data: data, encoding: .utf8) ?? "Could not convert to UTF8"
                print("ServerConnection received: \"\(dataString)\"")

                try await connection.send(data)
                print("ServerConnection sent: \"\(dataString)\"")
            }

            print("ServerConnection run() finished")
        }
    }
}

extension NetworkChannel.State {

    var isFinished: Bool {
        switch self {
        case .failed, .cancelled: true
        default: false
        }
    }
}
