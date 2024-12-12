public enum WaitingReasonEntity: Sendable, CaseIterable {
    case none
    case connectivity
    case serverBusy
    case apiLock
    case rateLimit
    case localLock
    case unknown
}
