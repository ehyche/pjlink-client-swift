import Foundation
import Network
import os

extension PJLink {

    public struct NetworkPJLinkEncoder: NetworkEncoder {
        private let logger: Logger

        public init() {
            logger = Logger(sub: .client, cat: .coder)
            logger.debug("NetworkPJLinkEncoder init()")
        }

        public func encode<T>(_ value: T) throws -> Data where T : Encodable {
            logger.debug("NetworkPJLinkEncoder encode<T>(_)")
            throw PJLink.Error.unimplementedMethod("PJLink.MessageEncoder.encode")
        }

        public func encode(_ value: PJLink.Message) throws -> Data {
            logger.debug("NetworkPJLinkEncoder encode(\(value))")
            return value.description.crTerminatedData
        }
    }
}
