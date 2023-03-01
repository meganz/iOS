
public struct ChatRoomDelegateEntity {
    public var onChatRoomUpdate: ((ChatRoomEntity) -> ())?
    public var onMessageLoaded: ((ChatMessageEntity) -> ())?
    public var onMessageReceived: ((ChatMessageEntity) -> ())?
    public var onMessageUpdate: ((ChatMessageEntity) -> ())?
    public var onHistoryReloaded: ((ChatRoomEntity) -> ())?
    public var onReactionUpdate: ((ChatIdEntity, String, Int) -> ())?
    
    public init(
        onChatRoomUpdate: ((ChatRoomEntity) -> Void)? = nil,
        onMessageLoaded: ((ChatMessageEntity) -> Void)? = nil,
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
