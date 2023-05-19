import MEGADomain

extension MEGAChatMessageType {
    func toChatMessageTypeEntity() -> ChatMessageTypeEntity {
        switch self {
        case .unknown:
            return .unknown
        case .invalid:
            return .invalid
        case .normal:
            return .normal
        case .alterParticipants:
            return .alterParticipants
        case .truncate:
            return .truncate
        case .privilegeChange:
            return .privilegeChange
        case .chatTitle:
            return .chatTitle
        case .callEnded:
            return .callEnded
        case .callStarted:
            return .callStarted
        case .publicHandleCreate:
            return .publicHandleCreate
        case .publicHandleDelete:
            return .publicHandleDelete
        case .setPrivateMode:
            return .setPrivateMode
        case .setRetentionTime:
            return .setRetentionTime
        case .attachment:
            return .attachment
        case .revokeAttachment:
            return .unknown
        case .contact:
            return .contact
        case .containsMeta:
            return .containsMeta
        case .voiceClip:
            return .voiceClip
        case .scheduledMeeting:
            return .scheduledMeeting
        @unknown default:
            if self.rawValue == 255 {
                return .loading
            } else if self.rawValue == -2 {
                return .joinedGroupChat
            } else {
                return .unknown
            }
        }
    }
}
