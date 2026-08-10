import Network

extension NWError {

    public var shouldReconnect: Bool {
        switch self {
        case .posix(let posixErrorCode):
            switch posixErrorCode {
            case .ENOTCONN, .ECONNRESET: true
            default: false
            }
        case .dns: false
        case .tls: false
        case .wifiAware: false
        @unknown default: false
        }
    }
}
