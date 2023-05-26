
public struct ChatRoomDelegateEntity {
    public var onChatRoomUpdate: ((ChatRoomEntity) -> Void)?
    public var onMessageLoaded: ((ChatMessageEntity?) -> Void)?
    public var onMessageReceived: ((ChatMessageEntity) -> Void)?
    public var onMessageUpdate: ((ChatMessageEntity) -> Void)?
    public var onHistoryReloaded: ((ChatRoomEntity) -> Void)?
    public var onReactionUpdate: ((ChatIdEntity, String, Int) -> Void)?
    
    public init(
        onChatRoomUpdate: ((ChatRoomEntity) -> Void)? = nil,
        onMessageLoaded: ((ChatMessageEntity?) -> Void)? = nil,
        onMessageReceived: ((ChatMessageEntity) -> Void)? = nil,
        onMessageUpdate: ((ChatMessageEntity) -> Void)? = nil,
        onHistoryReloaded: ((ChatRoomEntity) -> Void)? = nil,
        onReactionUpdate: ((ChatIdEntity, String, Int) -> Void)? = nil
    ) {
        self.onChatRoomUpdate = onChatRoomUpdate
        self.onMessageLoaded = onMessageLoaded
        self.onMessageReceived = onMessageReceived
        self.onMessageUpdate = onMessageUpdate
        self.onHistoryReloaded = onHistoryReloaded
        self.onReactionUpdate = onReactionUpdate
    }
}
