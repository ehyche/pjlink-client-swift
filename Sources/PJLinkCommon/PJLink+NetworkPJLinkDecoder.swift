import Foundation
import Network

extension PJLink {

    public struct NetworkPJLinkDecoder: NetworkDecoder {

        public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
            throw PJLink.Error.unimplementedMethod("PJLink.MessageDecoder.decode")
        }
    }
}

extension PJLink.NetworkPJLinkDecoder {

    public func decode(_ type: PJLink.Message.Type, from data: Data) throws -> PJLink.Message {
        try PJLink.Message(try data.toUTF8String())
    }
}
