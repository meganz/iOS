import MEGADomain

extension ChatTypeEntity {
    func toMEGAChatType() -> MEGAChatType {
        switch self {
        case .all:
            return .all
        case .individual:
            return .individual
        case .group:
            return .group
        case .groupPrivate:
            return .groupPrivate
        case .groupPublic:
            return .groupPublic
        case .meeting:
            return .meeting
        case .nonMeeting:
            return .nonMeeting
        }
    }
}

extension MEGAChatType {
    func toChatTypeEntity() -> ChatTypeEntity {
        switch self {
        case .all:
            return .all
        case .individual:
            return .individual
        case .group:
            return .group
        case .groupPrivate:
            return .groupPrivate
        case .groupPublic:
            return .groupPublic
        case .meeting:
            return .meeting
        case .nonMeeting:
            return .nonMeeting
        @unknown default:
            return .all
        }
    }
}
