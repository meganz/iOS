import MEGAChatSdk
import MEGADomain

public extension MEGAChatSession {
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
            audioDetected: session.isAudioDetected,
            isOnHold: session.isOnHold,
            changeType: session.changes.toChatSessionChange(),
            isHighResolution: session.isHighResVideo,
            isLowResolution: session.isLowResVideo,
            canReceiveVideoHiRes: session.canReceiveVideoHiRes,
            canReceiveVideoLowRes: session.canReceiveVideoLowRes,
            hasCamera: session.hasCamera,
            isLowResCamera: session.isLowResCamera,
            isHiResCamera: session.isHiResCamera,
            hasScreenShare: session.hasScreenShare,
            isLowResScreenShare: session.isLowResScreenShare,
            isHiResScreenShare: session.isHiResScreenShare,
            isModerator: session.isModerator,
            onRecording: session.isRecording
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

extension MEGAChatSessionChange {
    func toChatSessionChange() -> ChatSessionEntity.ChangeType {
        switch self {
        case .noChanges:
            return .noChanges
        case .status:
            return .status
        case .remoteAvFlags:
            return .remoteAvFlags
        case .speakRequested:
            return .speakRequested
        case .onLowRes:
            return .onLowRes
        case .onHiRes:
            return .onHiRes
        case .onHold:
            return .onHold
        case .audioLevel:
            return .audioLevel
        case .permissions:
            return .permission
        case .speakPermission:
            return .speakPermission
        case .onRecording:
            return .onRecording
        @unknown default:
            return .noChanges
        }
    }
}
