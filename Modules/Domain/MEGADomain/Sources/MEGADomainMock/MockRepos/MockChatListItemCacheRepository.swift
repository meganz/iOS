import MEGADomain

public final class MockChatListItemCacheRepository: ChatListItemCacheRepositoryProtocol, @unchecked Sendable {
    public static let newRepo: MockChatListItemCacheRepository = MockChatListItemCacheRepository()

    private var descriptionCache: [HandleEntity: ChatListItemDescriptionEntity]
    private var avatarCache: [HandleEntity: ChatListItemAvatarEntity]
    
    public init(
        descriptionCache: [HandleEntity: ChatListItemDescriptionEntity] = [:],
        avatarCache: [HandleEntity: ChatListItemAvatarEntity] = [:]
    ) {
        self.descriptionCache = descriptionCache
        self.avatarCache = avatarCache
    }

    public func description(for chatListItem: ChatListItemEntity) async -> ChatListItemDescriptionEntity? {
        descriptionCache[chatListItem.chatId]
    }
    
    public func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for chatListItem: ChatListItemEntity) async {
        descriptionCache[chatListItem.chatId] = chatListItemDescription
    }
    
    public func avatar(for chatListItem: ChatListItemEntity) async -> ChatListItemAvatarEntity? {
        avatarCache[chatListItem.chatId]
    }
    
    public func avatar(for scheduledMeeting: ScheduledMeetingEntity) async -> ChatListItemAvatarEntity? {
        avatarCache[scheduledMeeting.chatId]
    }
    
    public func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for chatRoom: ChatRoomEntity) async {
        avatarCache[chatRoom.chatId] = chatListItemAvatar
    }
}
