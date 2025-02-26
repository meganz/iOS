public struct NotificationSettingsEntity: Sendable {
    public init(
        globalChatsDndEnabled: Bool,
        globalChatsDndTimestamp: Int64
    ) {
        self.globalChatsDndEnabled = globalChatsDndEnabled
        self.globalChatsDndTimestamp = globalChatsDndTimestamp
    }
    
    public var globalChatsDndEnabled: Bool
    public var globalChatsDndTimestamp: Int64
}
