public struct NoteToSelfResolver: PitagTargetResolverProtocol {
    public init() {}
    
    public func resolve(forChats chats: [ChatListItemEntity], users: [UserEntity]) -> PitagTargetEntity? {
        guard chats.count == 1,
              users.isEmpty,
              let chat = chats.first,
              chat.isNoteToSelf else {
            return nil
        }
        return .noteToSelf
    }
}
