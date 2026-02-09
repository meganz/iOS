public struct Chat1To1ChatResolver: PitagTargetResolverProtocol {
    public init() {}
    
    public func resolve(forChats chats: [ChatListItemEntity], users: [UserEntity]) -> PitagTargetEntity? {
        guard chats.count == 1,
              users.isEmpty,
              let chat = chats.first,
              !chat.group,
              !chat.isNoteToSelf else {
            return nil
        }
        return .chat1To1
    }
}
