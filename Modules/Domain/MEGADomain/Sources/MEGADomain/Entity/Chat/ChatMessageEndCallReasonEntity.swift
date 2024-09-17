public enum ChatMessageEndCallReasonEntity: Sendable {
    case ended
    case rejected
    case noAnswer
    case failed
    case cancelled
    case byModerator
}

extension ChatMessageEndCallReasonEntity {
    public init?(_ int: Int) {
        switch int {
        case 1:
            self = .ended
        case 2:
            self = .rejected
        case 3:
            self = .noAnswer
        case 4:
            self = .failed
        case 5:
            self = .cancelled
        case 6:
            self = .byModerator
        default:
            return nil
        }
    }
}
