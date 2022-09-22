import MEGADomain

extension CallEntity {
    init(with call: MEGAChatCall) {
        self.status = CallStatusType(rawValue: call.status.rawValue)
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
            return session.toChatSessionEntity()
        })
            
        self.participants = (0..<call.participants.size).map { call.participants.megaHandle(at: $0) }
        self.uuid = call.uuid
    }
}
