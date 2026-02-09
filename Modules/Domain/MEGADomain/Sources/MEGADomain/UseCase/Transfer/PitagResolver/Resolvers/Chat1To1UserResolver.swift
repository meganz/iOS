public struct Chat1To1UserResolver: PitagTargetResolverProtocol {
    public init() {}
    
    public func resolve(forChats chats: [ChatListItemEntity], users: [UserEntity]) -> PitagTargetEntity? {
        guard users.count == 1, chats.isEmpty else {
            return nil
        }
        return .chat1To1
    }
}
