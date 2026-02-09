public struct MultipleChatsResolver: PitagTargetResolverProtocol {
    public init() {}
    
    public func resolve(forChats chats: [ChatListItemEntity], users: [UserEntity]) -> PitagTargetEntity? {
        let totalRecipients = chats.count + users.count
        return totalRecipients > 1 ? .multipleChats : nil
    }
}
