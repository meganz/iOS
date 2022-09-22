import MEGADomain

extension MEGAChatSession {
    func toChatSessionEntity() -> ChatSessionEntity {
        ChatSessionEntity(with: self)
    }
}

fileprivate extension ChatSessionEntity {
    init(with session: MEGAChatSession) {
        self.init(
            statusType: session.status.toStatusTypeEntity(),
            termCode: session.termCode.toTermCodeEntity(),
            hasAudio: session.hasAudio,
            hasVideo: session.hasVideo,
            peerId: session.peerId,
            clientId: session.clientId,
            audioDetected: session.audioDetected,
            isOnHold: session.isOnHold,
            changes: session.changes,
            isHighResolution: session.isHighResVideo,
            isLowResolution: session.isLowResVideo,
            canReceiveVideoHiRes: session.canReceiveVideoHiRes,
            canReceiveVideoLowRes: session.canReceiveVideoLowRes
        )
    }
}

extension MEGAChatSessionStatus {
    func toStatusTypeEntity() -> ChatSessionEntity.StatusType {
        switch self {
        case .invalid:
            return .invalid
        case .inProgress:
            return .inProgress
        case .destroyed:
            return .destroyed
        @unknown default:
            return .invalid
        }
    }
}

extension MEGAChatSessionTermCode {
    func toTermCodeEntity() -> ChatSessionEntity.ChatSessionTermCode {
        switch self {
        case .invalid:
            return .invalid
        case .recoverable:
            return .recoverable
        case .nonRecoverable:
            return .nonRecoverable
        @unknown default:
            return .invalid
        }
    }
}
