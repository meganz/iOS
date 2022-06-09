
extension ChatSessionEntity {
    init(with session: MEGAChatSession) {
        self.statusType = StatusType(rawValue: session.status.rawValue)
        self.termCode = ChatSessionTermCode(rawValue: session.termCode.rawValue)
        self.hasAudio = session.hasAudio
        self.hasVideo = session.hasVideo
        self.peerId = session.peerId
        self.clientId = session.clientId
        self.audioDetected = session.audioDetected
        self.isOnHold = session.isOnHold
        self.changes = session.changes
        self.isHighResolution = session.isHighResVideo
        self.isLowResolution = session.isLowResVideo
        self.canReceiveVideoHiRes = session.canReceiveVideoHiRes
        self.canReceiveVideoLowRes = session.canReceiveVideoLowRes
    }
}
