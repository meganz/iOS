import MEGAChatSdk
import MEGADomain

extension ChatMessageScheduledMeetingChangeType {
    func toMEGAScheduledMeetingChangeType() -> MEGAChatMessageScheduledMeetingChangeType? {
        switch self {
        case .parent:
            return .parent
        case .timezone:
            return .timezone
        case .startDate:
            return .startDate
        case .endDate:
            return .endDate
        case .title:
            return .title
        case .description:
            return .description
        case .attributes:
            return .attributes
        case .override:
            return .cancelled
        case .cancelled:
            return .cancelled
        case .flags:
            return .flags
        case .rules:
            return .rules
        case .none:
            return nil
        }
    }
}
