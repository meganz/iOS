

protocol ChatRoomRepositoryProtocol {
    func chatRoom(forChatId chatId: MEGAHandle) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: MEGAHandle) -> ChatRoomEntity?
    func peerHandles(forChatId chatId: MEGAHandle) -> [MEGAHandle]
    func createChatRoom(forUserHandle userHandle: MEGAHandle, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func createPublicLink(forChatId chatId: MEGAHandle, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func queryChatLink(forChatId chatId: MEGAHandle, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userFullName(forPeerId peerId: MEGAHandle, chatId: MEGAHandle, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func userFullName(forPeerId peerId: MEGAHandle, chatId: MEGAHandle) async throws -> String
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
}

