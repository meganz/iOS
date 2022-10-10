import Combine
import MEGADomain

protocol ChatRoomUseCaseProtocol {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomPrivilegeEntity?
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userDisplayName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String]
    func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool
    mutating func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never>
    mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never>
    mutating func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never>
}

struct ChatRoomUseCase<T: ChatRoomRepositoryProtocol, U: UserStoreRepositoryProtocol>: ChatRoomUseCaseProtocol {
    private var chatRoomRepo: T
    private let userStoreRepo: U
    
    init(chatRoomRepo: T, userStoreRepo: U) {
        self.chatRoomRepo = chatRoomRepo
        self.userStoreRepo = userStoreRepo
    }
    
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forChatId: chatId)
    }
    
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forUserHandle: userHandle)
    }
    
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.createChatRoom(forUserHandle: userHandle, completion: completion)
    }
    
    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity] {
        chatRoomRepo.peerHandles(forChatId: chatId)
    }
    
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomPrivilegeEntity? {
        chatRoomRepo.peerPrivilege(forUserHandle: userHandle, inChatId: chatId)
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
    
    func userDisplayName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        if let displayName = userStoreRepo.getDisplayName(forUserHandle: peerId) {
            completion(.success(displayName))
            return
        }

        chatRoomRepo.userFullName(forPeerId: peerId, chatId: chatId, completion: completion)
    }
    
    func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for peerId in peerIds {
                group.addTask {
                    if let nickName = await userStoreRepo.displayName(forUserHandle: peerId) {
                        return nickName
                    }
                    
                    return try await chatRoomRepo.userFullName(forPeerId: peerId, chatId: chatId)
                }
            }
                        
            return try await group.reduce(into: [String]()) { result, name in
                result.append(name)
            }
        }
    }

    func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.renameChatRoom(chatId: chatId, title: title, completion: completion)
    }
    
    func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool {
        try await chatRoomRepo.allowNonHostToAddParticipants(enabled: enabled, chatId: chatId)
    }
    
    mutating func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomRepo.participantsUpdated(forChatId: chatId)
    }
    
    mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomRepo.userPrivilegeChanged(forChatId: chatId)
    }
    
    mutating func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never> {
        if chatRoomRepo.isChatRoomOpen(chatId: chatId) == false {
            try? chatRoomRepo.openChatRoom(chatId: chatId) { _ in }
        }
        
        return chatRoomRepo.allowNonHostToAddParticipantsValueChanged(forChatId: chatId)
    }
}
