import Foundation

public protocol ChatListItemCacheUseCaseProtocol: Sendable {
    func description(for chatListItem: ChatListItemEntity) async -> ChatListItemDescriptionEntity?
    func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for chatListItem: ChatListItemEntity) async
    func avatar(for chatListItem: ChatListItemEntity) async -> ChatListItemAvatarEntity?
    func avatar(for scheduledMeeting: ScheduledMeetingEntity) async -> ChatListItemAvatarEntity?
    func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for chatRoom: ChatRoomEntity) async
}

public struct ChatListItemCacheUseCase<T: ChatListItemCacheRepositoryProtocol>: ChatListItemCacheUseCaseProtocol {
    private let repository: T

    public init(repository: T) {
        self.repository = repository
    }
    
    public func description(for chatListItem: ChatListItemEntity) async -> ChatListItemDescriptionEntity? {
        await repository.description(for: chatListItem)
    }
    
    public func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for chatListItem: ChatListItemEntity) async {
        await repository.setDescription(chatListItemDescription, for: chatListItem)
    }
    
    public func avatar(for chatListItem: ChatListItemEntity) async -> ChatListItemAvatarEntity? {
        await repository.avatar(for: chatListItem)
    }
    
    public func avatar(for scheduledMeeting: ScheduledMeetingEntity) async -> ChatListItemAvatarEntity? {
        await repository.avatar(for: scheduledMeeting)
    }
    
    public func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for chatRoom: ChatRoomEntity) async {
        await repository.setAvatar(chatListItemAvatar, for: chatRoom)
    }
}
