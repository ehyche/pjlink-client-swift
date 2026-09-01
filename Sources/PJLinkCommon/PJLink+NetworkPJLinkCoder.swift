import Network
import os

extension PJLink {

    public struct NetworkPJLinkCoder: NetworkCoder {
        private let logger: Logger

        public init() {
            logger = Logger(sub: .client, cat: .coder)
            logger.debug("NetworkPJLinkCoder init()")
        }

        public func makeDecoder() -> NetworkPJLinkDecoder {
            logger.debug("NetworkPJLinkCoder makeDecoder()")
            return NetworkPJLinkDecoder()
        }

        public func makeEncoder() -> NetworkPJLinkEncoder {
            logger.debug("NetworkPJLinkCoder makeEncoder()")
            return NetworkPJLinkEncoder()
        }
    }
}
