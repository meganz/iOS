public protocol ChatListItemCacheRepositoryProtocol: RepositoryProtocol, Sendable {
    func description(for chatListItem: ChatListItemEntity) async -> ChatListItemDescriptionEntity?
    func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for chatListItem: ChatListItemEntity) async
    func avatar(for chatListItem: ChatListItemEntity) async -> ChatListItemAvatarEntity?
    func avatar(for scheduledMeeting: ScheduledMeetingEntity) async -> ChatListItemAvatarEntity?
    func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for chatRoom: ChatRoomEntity) async
}
