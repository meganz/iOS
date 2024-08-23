import MEGADomain

public final class MockChatListItemCacheUseCase: ChatListItemCacheUseCaseProtocol, @unchecked Sendable {
    private let chatListItemDescription: ChatListItemDescriptionEntity?
    private let chatListItemAvatar: ChatListItemAvatarEntity?
    
    var setDescription_callTimes = 0
    var setAvatar_callTimes = 0
    
    public init(
        chatListItemDescription: ChatListItemDescriptionEntity? = nil,
        chatListItemAvatar: ChatListItemAvatarEntity? = nil
    ) {
        self.chatListItemDescription = chatListItemDescription
        self.chatListItemAvatar = chatListItemAvatar
    }
    
    public func description(for chatListItem: ChatListItemEntity) async -> ChatListItemDescriptionEntity? {
        chatListItemDescription
    }
    
    public func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for chatListItem: ChatListItemEntity) async {
        setDescription_callTimes += 1
    }
    
    public func avatar(for chatListItem: ChatListItemEntity) async -> ChatListItemAvatarEntity? {
        chatListItemAvatar
    }
    
    public func avatar(for scheduledMeeting: ScheduledMeetingEntity) async -> ChatListItemAvatarEntity? {
        chatListItemAvatar
    }
    
    public func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for chatRoom: ChatRoomEntity) async {
        setAvatar_callTimes += 1
    }
}
