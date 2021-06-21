
protocol ChatRoomUseCaseProtocol {
    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity?
    func createChatRoom(forUserHandle userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, Error>) -> Void)
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkError>) -> Void)
    func userDisplayName(forPeerId peerId: UInt64, chatId: UInt64, completion: @escaping (Result<String, Error>) -> Void)
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
}

struct ChatRoomUseCase: ChatRoomUseCaseProtocol {
    private let chatRoomRepo: ChatRoomRepositoryProtocol
    private let userStoreRepo: UserStoreRepositoryProtocol
    
    init(chatRoomRepo: ChatRoomRepositoryProtocol, userStoreRepo: UserStoreRepositoryProtocol) {
        self.chatRoomRepo = chatRoomRepo
        self.userStoreRepo = userStoreRepo
    }
    
    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forUserHandle: userHandle)
    }
    
    func createChatRoom(forUserHandle userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, Error>) -> Void) {
        chatRoomRepo.createChatRoom(forUserHandle: userHandle, completion: completion)
    }
    
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkError>) -> Void) {
        guard chatRoom.isMeeting || chatRoom.isPublicChat || chatRoom.isGroup else {
            // Not allowed to create/query chat link
            completion(.failure(.creatingChatLinkNotAllowed))
            return
        }
        
        chatRoomRepo.queryChatLink(forChatId: chatRoom.chatId, completion: completion)
    }
    
    func userDisplayName(forPeerId peerId: UInt64, chatId: UInt64, completion: @escaping (Result<String, Error>) -> Void) {
        if let displayName = userStoreRepo.getDisplayName(forUserHandle: peerId) {
            completion(.success(displayName))
            return
        }

        chatRoomRepo.userFullName(forPeerId: peerId, chatId: chatId, completion: completion)
    }
    
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.renameChatRoom(chatId: chatId, title: title, completion: completion)
    }
}
