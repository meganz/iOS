import MEGAChatSdk
import MEGADomain

extension MEGAChatMessageEndCallReason {
    func toChatListItemChangeEntity() -> ChatMessageEndCallReasonEntity? {
        switch self {
        case .ended:
            return .ended
        case .rejected:
            return .rejected
        case .noAnswer:
            return .noAnswer
        case .failed:
            return .failed
        case .cancelled:
            return .cancelled
        case .byModerator:
            return .byModerator
        @unknown default:
            return nil
        }
    }
}
