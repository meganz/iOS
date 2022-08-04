import Combine

protocol ChatRoomRepositoryProtocol {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomEntity.Privilege?
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func createPublicLink(forChatId chatId: HandleEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func queryChatLink(forChatId chatId: HandleEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userFullName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func userFullName(forPeerId peerId: HandleEntity, chatId: HandleEntity) async throws -> String
    func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    mutating func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never>
    mutating func userPrivilegeChanged(forChatId: HandleEntity) -> AnyPublisher<HandleEntity, Never>
}

