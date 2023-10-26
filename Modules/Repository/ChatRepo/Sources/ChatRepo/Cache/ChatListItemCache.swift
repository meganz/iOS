import Foundation
import MEGADomain

public protocol ChatListItemCacheProtocol: Actor {
    func description(for handle: HandleEntity) -> ChatListItemDescriptionEntity?
    func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for handle: HandleEntity)
    func avatar(for handle: HandleEntity) -> ChatListItemAvatarEntity?
    func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for handle: HandleEntity)
    func removeAllCachedValues()
}

public actor ChatListItemCache: ChatListItemCacheProtocol {
    public static let shared = ChatListItemCache()
    
    private let chatListItemDescriptionCache = NSCache<NSNumber, ChatListItemDescriptionEntityProxy>()
    private let chatListItemAvatarCache = NSCache<NSNumber, ChatListItemAvatarEntityProxy>()
    
    public func setDescription(_ chatListItemDescription: ChatListItemDescriptionEntity, for handle: HandleEntity) {
        let key = NSNumber(value: handle)
        let value = ChatListItemDescriptionEntityProxy(
            chatRoomDescriptionEntity: chatListItemDescription
        )
        chatListItemDescriptionCache.setObject(value, forKey: key)
    }
    
    public func description(for handle: HandleEntity) -> ChatListItemDescriptionEntity? {
        chatListItemDescriptionCache.object(forKey: NSNumber(value: handle))?.chatRoomDescriptionEntity
    }
    
    public func setAvatar(_ chatListItemAvatar: ChatListItemAvatarEntity, for handle: HandleEntity) {
        let key = NSNumber(value: handle)
        let value = ChatListItemAvatarEntityProxy(chatRoomAvatarEntity: chatListItemAvatar)
        chatListItemAvatarCache.setObject(value, forKey: key)
    }
    
    public func avatar(for handle: HandleEntity) -> ChatListItemAvatarEntity? {
        chatListItemAvatarCache.object(forKey: NSNumber(value: handle))?.chatRoomAvatarEntity
    }
    
    public func removeAllCachedValues() {
        chatListItemDescriptionCache.removeAllObjects()
        chatListItemAvatarCache.removeAllObjects()
    }
}

private final class ChatListItemAvatarEntityProxy {
    let chatRoomAvatarEntity: ChatListItemAvatarEntity
    init(chatRoomAvatarEntity: ChatListItemAvatarEntity) {
        self.chatRoomAvatarEntity = chatRoomAvatarEntity
    }
}

private final class ChatListItemDescriptionEntityProxy {
    let chatRoomDescriptionEntity: ChatListItemDescriptionEntity
    init(chatRoomDescriptionEntity: ChatListItemDescriptionEntity) {
        self.chatRoomDescriptionEntity = chatRoomDescriptionEntity
    }
}
