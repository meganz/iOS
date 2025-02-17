import MEGAChatSdk
import MEGADomain

public extension ChatStatusEntity {
    func toMEGAChatStatus() -> MEGAChatStatus {
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

public extension MEGAChatStatus {
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
        @unknown default:
            return .invalid
        }
    }
}
