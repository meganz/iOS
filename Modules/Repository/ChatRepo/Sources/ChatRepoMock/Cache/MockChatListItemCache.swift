import ChatRepo
import MEGADomain

public actor MockChatListItemCache: ChatListItemCacheProtocol {
    private var descriptionCache: [HandleEntity: ChatListItemDescriptionEntity]
    private var avatarCache: [HandleEntity: ChatListItemAvatarEntity]

    public init(
        descriptionCache: [HandleEntity: ChatListItemDescriptionEntity] = [:],
        avatarCache: [HandleEntity: ChatListItemAvatarEntity] = [:]
    ) {
        self.descriptionCache = descriptionCache
        self.avatarCache = avatarCache
    }
    
    public func description(for handle: HandleEntity) -> ChatListItemDescriptionEntity? {
        descriptionCache[handle]
    }
    
    public func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for handle: HandleEntity) {
        descriptionCache[handle] = chatListItemDescription
    }
    
    public func avatar(for handle: HandleEntity) -> ChatListItemAvatarEntity? {
        avatarCache[handle]
    }
    
    public func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for handle: HandleEntity) {
        avatarCache[handle] = chatListItemAvatar
    }
    
    public func removeAllCachedValues() {
        descriptionCache = [:]
        avatarCache = [:]
    }
}
