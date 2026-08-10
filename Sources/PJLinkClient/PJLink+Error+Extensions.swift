import PJLinkCommon

extension PJLink.Error {

    public var shouldReconnect: Bool {
        switch self {
        case .emptyDataBufferReceived: true
        default: false
        }
    }
}
