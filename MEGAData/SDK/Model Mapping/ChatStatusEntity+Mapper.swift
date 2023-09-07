import MEGADomain

extension ChatStatusEntity {
    func toChatStatus() -> ChatStatus {
        switch self {
        case .offline:
            return .offline
        case .away:
            return .away
        case .online:
            return .online
        case .busy:
            return .busy
        case .invalid:
            return .invalid
        }
    }
}

extension ChatStatus {
    func toChatStatusEntity() -> ChatStatusEntity {
        switch self {
        case .offline:
            return .offline
        case .away:
            return .away
        case .online:
            return .online
        case .busy:
            return.busy
        case .invalid:
            return .invalid
        }
    }
}
