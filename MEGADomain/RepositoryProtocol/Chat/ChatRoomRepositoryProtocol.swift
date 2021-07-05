

protocol ChatRoomRepositoryProtocol {
    func chatRoom(forChatId chatId: UInt64) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity?
    func createChatRoom(forUserHandle userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, Error>) -> Void)
    func createPublicLink(forChatId chatId: UInt64, completion: @escaping (Result<String, ChatLinkError>) -> Void)
    func queryChatLink(forChatId chatId: UInt64, completion: @escaping (Result<String, ChatLinkError>) -> Void)
    func userFullName(forPeerId peerId: UInt64, chatId: UInt64, completion: @escaping (Result<String, Error>) -> Void)
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
}

