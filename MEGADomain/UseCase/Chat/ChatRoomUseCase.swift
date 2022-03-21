
protocol ChatRoomUseCaseProtocol {
    func chatRoom(forChatId chatId: MEGAHandle) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: MEGAHandle) -> ChatRoomEntity?
    func createChatRoom(forUserHandle userHandle: MEGAHandle, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userDisplayName(forPeerId peerId: MEGAHandle, chatId: MEGAHandle, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
}

struct ChatRoomUseCase<T: ChatRoomRepositoryProtocol, U: UserStoreRepositoryProtocol>: ChatRoomUseCaseProtocol {
    private let chatRoomRepo: T
    private let userStoreRepo: U
    
    init(chatRoomRepo: T, userStoreRepo: U) {
        self.chatRoomRepo = chatRoomRepo
        self.userStoreRepo = userStoreRepo
    }
    
    func chatRoom(forChatId chatId: MEGAHandle) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forChatId: chatId)
    }
    
    func chatRoom(forUserHandle userHandle: MEGAHandle) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forUserHandle: userHandle)
    }
    
    func createChatRoom(forUserHandle userHandle: MEGAHandle, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.createChatRoom(forUserHandle: userHandle, completion: completion)
    }
    
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
        guard chatRoom.chatType != .oneToOne else {
            // Not allowed to create/query chat link
            completion(.failure(.creatingChatLinkNotAllowed))
            return
        }
        
        if chatRoom.ownPrivilege == .moderator {
            chatRoomRepo.queryChatLink(forChatId: chatRoom.chatId) { result in
                // If the user is a moderator and the link is not generated yet. Generate the link.
                if case let .failure(error) = result, error == .resourceNotFound {
                    chatRoomRepo.createPublicLink(forChatId: chatRoom.chatId, completion: completion)
                } else {
                    completion(result)
                }
            }
        } else {
            chatRoomRepo.queryChatLink(forChatId: chatRoom.chatId, completion: completion)
        }
    }
    
    func userDisplayName(forPeerId peerId: MEGAHandle, chatId: MEGAHandle, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
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
