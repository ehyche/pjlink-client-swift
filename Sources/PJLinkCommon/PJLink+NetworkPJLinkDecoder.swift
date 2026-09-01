import Foundation
import Network
import os

extension PJLink {

    public struct NetworkPJLinkDecoder: NetworkDecoder {
        private let logger: Logger

        public init() {
            logger = Logger(sub: .client, cat: .coder)
            logger.debug("NetworkPJLinkDecoder init()")
        }

        public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
            logger.debug("NetworkPJLinkDecoder decode<T>(_, from: \(data.count))")
            throw PJLink.Error.unimplementedMethod("PJLink.MessageDecoder.decode")
        }

        public func decode(_ type: PJLink.Message.Type, from data: Data) throws -> PJLink.Message {
            logger.debug("NetworkPJLinkDecoder decode(PJLink.Message.Type, from: \(data.count))")
            return try PJLink.Message(try data.toUTF8String())
        }
    }
}
