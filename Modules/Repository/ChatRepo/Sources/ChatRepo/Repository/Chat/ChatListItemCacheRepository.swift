import Foundation
import MEGADomain

public struct ChatListItemCacheRepository: ChatListItemCacheRepositoryProtocol {
    public static var newRepo: ChatListItemCacheRepository {
        ChatListItemCacheRepository(chatListItemCache: ChatListItemCache.shared)
    }
    
    private let chatListItemCache: any ChatListItemCacheProtocol

    public init(chatListItemCache: some ChatListItemCacheProtocol) {
        self.chatListItemCache = chatListItemCache
    }
    
    public func description(for chatListItem: ChatListItemEntity) async -> ChatListItemDescriptionEntity? {
        await chatListItemCache.description(for: chatListItem.chatId)
    }
    
    public func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for chatListItem: ChatListItemEntity) async {
        await chatListItemCache.setDescription(chatListItemDescription, for: chatListItem.chatId)
    }
    
    public func avatar(for chatListItem: ChatListItemEntity) async -> ChatListItemAvatarEntity? {
        await chatListItemCache.avatar(for: chatListItem.chatId)
    }
    
    public func avatar(for scheduledMeeting: ScheduledMeetingEntity) async -> ChatListItemAvatarEntity? {
        await chatListItemCache.avatar(for: scheduledMeeting.chatId)
    }
    
    public func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for chatRoom: ChatRoomEntity) async {
        await chatListItemCache.setAvatar(chatListItemAvatar, for: chatRoom.chatId)
    }
}
