import MEGADomain

extension MEGAChatMessageStatus {
    func toChatMessageStatusEntity() -> ChatMessageStatusEntity? {
        switch self {
        case .unknown:
            return .unknown
        case .sending:
            return .sending
        case .sendingManual:
            return .sendingManual
        case .serverReceived:
            return .serverRejected
        case .delivered:
            return .delivered
        case .notSeen:
            return .notSeen
        case .seen:
            return .seen
        case .serverRejected:
            return .serverRejected
        @unknown default:
            return nil
        }
    }
}
