public enum ChatMessageStatusEntity: Sendable {
    case unknown
    case sending
    case sendingManual
    case serverReceived
    case serverRejected
    case delivered
    case notSeen
    case seen
}
