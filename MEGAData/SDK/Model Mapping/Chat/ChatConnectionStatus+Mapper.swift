import MEGADomain

extension MEGAChatConnection {
    func toChatConnectionStatus() -> ChatConnectionStatus {
        switch self {
        case .offline:
            return .offline
        case .inProgress:
            return .inProgress
        case .logging:
            return .logging
        case .online:
            return .online
        @unknown default:
            return .invalid
        }
    }
}
