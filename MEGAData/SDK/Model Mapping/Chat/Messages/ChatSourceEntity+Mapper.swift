import MEGADomain

extension MEGAChatSource {
    func toChatSourceEntity() -> ChatSourceEntity {
        switch self {
        case .error:
            return .error
        case .none:
            return .none
        case .local:
            return .local
        case .remote:
            return .remote
        @unknown default:
            return .error
        }
    }
}
