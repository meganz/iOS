public struct ChatPresenceConfigEntity: Sendable {
    
    public init(status: ChatStatusEntity, autoAwayEnabled: Bool, autoAwayTimeout: Int64, persist: Bool, pending: Bool, lastGreenVisible: Bool) {
        self.status = status
        self.autoAwayEnabled = autoAwayEnabled
        self.autoAwayTimeout = autoAwayTimeout
        self.persist = persist
        self.pending = pending
        self.lastGreenVisible = lastGreenVisible
    }
    
    public let status: ChatStatusEntity
    public let autoAwayEnabled: Bool
    public let autoAwayTimeout: Int64
    public let persist: Bool
    public let pending: Bool
    public let lastGreenVisible: Bool
}
