//
//  PJLink+UDPListener.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 3/3/26.
//

import Foundation
import Network
import os

extension PJLink {
    public struct UDPListener: Sendable {
        private let task: Task<Void, Swift.Error>
        public let outputStream: AsyncThrowingStream<Output, Swift.Error>
        private let continuation: AsyncThrowingStream<Output, Swift.Error>.Continuation

        public struct Output: Sendable {
            public let host: NWEndpoint.Host?
            public let data: Data
        }

        public init(port: NWEndpoint.Port) throws {
            let logger = Logger(sub: .common, cat: .udpListener)
            let listener = try NetworkListener(
                using: .parameters {
                    UDP()
                }
                .localPort(port)
            )
            listener.onServiceRegistrationUpdate { listener, change in
                logger.debug("onServiceRegistrationUpdate \(change.name, privacy: .public)")
            }
            listener.onStateUpdate { listener, state in
                logger.debug("onStateUpdate: \(state.name, privacy: .public)")
            }
            let (stream, continuation) = AsyncThrowingStream.makeStream(of: Output.self)
            self.task = Task {
                continuation.onTermination = { term in
                    logger.debug("onTermination: \(term.displayName, privacy: .public)")
                }
                do {
                    try await listener.run { connection in
                        logger.debug("New Connection: \(connection.id)")
                        do {
                            let output = Output(
                                host: connection.remoteEndpoint?.host,
                                data: try await connection.receive().content
                            )
                            logger.info("RECV: \(output, privacy: .public)")
                            continuation.yield(output)
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            self.outputStream = stream
            self.continuation = continuation
        }

        public func cancel() {
            let logger = Logger(sub: .common, cat: .udpListener)
            logger.debug("cancel()")
            continuation.finish()
            task.cancel()
        }
    }
}

extension PJLink.UDPListener.Output: CustomStringConvertible {

    public var description: String {
        "\"\(String(describing: data.utf8StringWithCRStripped))\" from \(String(describing: host?.debugDescription))"
    }
}

extension AsyncThrowingStream.Continuation.Termination where Failure: Swift.Error {

    var displayName: String {
        switch self {
        case .finished(let failure): ".finished(\(String(describing: failure)))"
        case .cancelled: ".cancelled"
        @unknown default: "Unknown"
        }
    }
}
