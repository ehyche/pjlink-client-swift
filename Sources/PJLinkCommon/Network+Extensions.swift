//
//  Network+Extensions.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 3/3/26.
//

import Network
import ConcurrencyExtras

extension NetworkListener.State {

    public var name: String {
        switch self {
        case .setup: ".setup"
        case .waiting(let error): ".waiting(\(error))"
        case .ready: ".ready"
        case .failed(let error): ".failed(\(error))"
        case .cancelled: ".cancelled"
        @unknown default: "Unknown"
        }
    }
}

extension NetworkListener.ServiceRegistrationChange {

    public var name: String {
        switch self {
        case .add(let nwEndpoint): ".add(\(nwEndpoint.debugDescription))"
        case .remove(let nwEndpoint): ".remove(\(nwEndpoint.debugDescription))"
        @unknown default: "Unknown"
        }
    }
}

extension NWEndpoint {

    public var host: NWEndpoint.Host? {
        switch self {
        case .hostPort(let host, _): host
        default: nil
        }
    }
}

extension NWEndpoint.Port {

    public static let pjlink: Self = 4352
}

extension NetworkConnection where ApplicationProtocol == Framer<PJLinkFramer> {

    public func receivePJLinkMessage() async throws -> PJLink.Message {
        try PJLink.Message(try await receive().content)
    }

    public func sendPJLinkMessage(_ message: PJLink.Message) async throws {
        try await send(message.description.utf8Data)
    }

    public var pjlinkMessages: AsyncThrowingStream<PJLink.Message, any Error> {
        UncheckedSendable(messages.map { try PJLink.Message($0.content) })
            .eraseToThrowingStream()
    }
}
