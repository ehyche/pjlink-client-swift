import Network

extension PJLink {

    public struct NetworkPJLinkCoder: NetworkCoder {
        public init() {}

        public func makeDecoder() -> NetworkPJLinkDecoder { NetworkPJLinkDecoder() }

        public func makeEncoder() -> NetworkPJLinkEncoder { NetworkPJLinkEncoder() }
    }
}
