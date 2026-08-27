import Foundation
import Network

extension PJLink {

    public struct NetworkPJLinkEncoder: NetworkEncoder {

        public func encode<T>(_ value: T) throws -> Data where T : Encodable {
            throw PJLink.Error.unimplementedMethod("PJLink.MessageEncoder.encode")
        }
    }
}

extension PJLink.NetworkPJLinkEncoder {

    public func encode(_ value: PJLink.Message) throws -> Data {
        value.description.crTerminatedData
    }
}
