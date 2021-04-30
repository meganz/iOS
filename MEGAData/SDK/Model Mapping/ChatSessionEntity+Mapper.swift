
extension ChatSessionEntity {
    init(with session: MEGAChatSession) {
        self.statusType = StatusType(rawValue: session.status.rawValue)
        self.hasAudio = session.hasAudio
        self.hasVideo = session.hasVideo
        self.peerId = session.peerId
        self.clientId = session.clientId
        self.audioDetected = session.audioDetected
        self.isOnHold = session.isOnHold
        self.changes = session.changes
    }
}
