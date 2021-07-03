
extension CallEntity {
    init(with call: MEGAChatCall) {
        self.status = call.toStatus()
        self.chatId = call.chatId
        self.callId = call.callId
        self.changeTye = ChangeType(rawValue: call.changes.rawValue)
        self.duration = call.duration
        self.initialTimestamp = call.initialTimeStamp
        self.finalTimestamp = call.finalTimeStamp
        self.hasLocalAudio = call.hasLocalAudio
        self.hasLocalVideo = call.hasLocalVideo
        self.termCodeType = TermCodeType(rawValue: call.termCode.rawValue)
        self.isRinging = call.isRinging
        self.callCompositionChange = CompositionChangeType(rawValue: call.callCompositionChange.rawValue)

        self.numberOfParticipants = call.numParticipants
        self.isOnHold = call.isOnHold
        self.sessionClientIds = (0..<call.sessionsClientId.size).map { call.sessionsClientId.megaHandle(at: $0) }
        self.clientSessions = self.sessionClientIds.compactMap({ sessionClientId in
            guard let session = call.session(forClientId: sessionClientId) else { return nil }
            return ChatSessionEntity(with: session)
        })
            
        self.participants = (0..<call.participants.size).map { call.participants.megaHandle(at: $0) }
        self.uuid = call.uuid
    }
}

extension MEGAChatCall {
    func toStatus() -> CallEntity.CallStatusType {
        switch status {
        case .undefined:
            return .undefined
        case .initial:
            return .initial
        case .userNoPresent:
            return .userNoPresent
        case .connecting:
            return .connecting
        case .joining:
            return .joining
        case .inProgress:
            return .inProgress
        case .terminatingUserParticipation:
            return .userNoPresent
        case .destroyed:
            return .destroyed
        @unknown default:
            return .undefined
        }
    }
}
