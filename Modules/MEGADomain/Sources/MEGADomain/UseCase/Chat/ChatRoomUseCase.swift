import Combine

public protocol ChatRoomUseCaseProtocol {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomPrivilegeEntity?
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userDisplayName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String]
    func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool
    func message(forChatId chatId: ChatIdEntity, messageId: HandleEntity) -> ChatMessageEntity?
    func archive(_ archive: Bool, chatId: ChatIdEntity)
    func setMessageSeenForChat(forChatId chatId: ChatIdEntity,  messageId: HandleEntity)
    func base64Handle(forChatId chatId: ChatIdEntity) -> String?
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String?
    func userFullNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String]
    func userNickNames(forChatId chatId: ChatIdEntity) async throws -> [HandleEntity: String]
    func userEmails(forChatId chatId: ChatIdEntity) async throws -> [HandleEntity: String]
    mutating func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never>
    mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never>
    func ownPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never>
    mutating func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never>
    func closeChatRoomPreview(chatRoom: ChatRoomEntity)
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity)
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity)
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity)
}

public struct ChatRoomUseCase<T: ChatRoomRepositoryProtocol, U: UserStoreRepositoryProtocol>: ChatRoomUseCaseProtocol {
    private var chatRoomRepo: T
    private let userStoreRepo: U
    
    public init(chatRoomRepo: T, userStoreRepo: U) {
        self.chatRoomRepo = chatRoomRepo
        self.userStoreRepo = userStoreRepo
    }
    
    public func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forChatId: chatId)
    }
    
    public func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity? {
        chatRoomRepo.chatRoom(forUserHandle: userHandle)
    }
    
    public func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.createChatRoom(forUserHandle: userHandle, completion: completion)
    }
    
    public func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity] {
        chatRoomRepo.peerHandles(forChatId: chatId)
    }
    
    public func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomPrivilegeEntity? {
        chatRoomRepo.peerPrivilege(forUserHandle: userHandle, inChatId: chatId)
    }
    
    public func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        chatRoomRepo.userStatus(forUserHandle: userHandle)
    }

    public func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
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
    
    public func userDisplayName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        if let displayName = userStoreRepo.getDisplayName(forUserHandle: peerId) {
            completion(.success(displayName))
            return
        }

        chatRoomRepo.userFullName(forPeerId: peerId, chatId: chatId, completion: completion)
    }
    
    public func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String] {
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

    public func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.renameChatRoom(chatId: chatId, title: title, completion: completion)
    }
    
    public func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool {
        try await chatRoomRepo.allowNonHostToAddParticipants(enabled: enabled, chatId: chatId)
    }
    
    public func message(forChatId chatId: ChatIdEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        chatRoomRepo.message(forChatId: chatId, messageId: messageId)
    }
    
    public func archive(_ archive: Bool, chatId: ChatIdEntity) {
        chatRoomRepo.archive(archive, chatId: chatId)
    }
    
    public func setMessageSeenForChat(forChatId chatId: ChatIdEntity,  messageId: HandleEntity) {
        chatRoomRepo.setMessageSeenForChat(forChatId: chatId, messageId: messageId)
    }
    
    public func base64Handle(forChatId chatId: ChatIdEntity) -> String? {
        chatRoomRepo.base64Handle(forChatId: chatId)
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        chatRoomRepo.contactEmail(forUserHandle: userHandle)
    }
    
    public func userFullNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for peerId in peerIds {
                group.addTask { try await chatRoomRepo.userFullName(forPeerId: peerId, chatId: chatId) }
            }
                        
            return try await group.reduce(into: [String]()) { result, name in
                result.append(name)
            }
        }
    }
    
    public func userNickNames(forChatId chatId: ChatIdEntity) async throws -> [HandleEntity: String] {
        guard let chatRoom = chatRoom(forChatId: chatId) else {
            throw ChatRoomErrorEntity.noChatRoomFound
        }
        
        return await withTaskGroup(
            of: [HandleEntity: String]?.self,
            returning: [HandleEntity: String].self
        ) { group in
            for peerId in chatRoom.peers.map(\.handle) {
                group.addTask {
                    if let displayName = await userStoreRepo.displayName(forUserHandle: peerId) {
                        return [peerId: displayName]
                    } else {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [HandleEntity: String]()){ result, handleEntityNamePair in
                if let handleEntityNamePair {
                    for (key, value) in handleEntityNamePair {
                        result[key] = value
                    }
                }
            }
        }
    }
    
    public func userEmails(forChatId chatId: ChatIdEntity) async throws -> [HandleEntity: String] {
        guard let chatRoom = chatRoom(forChatId: chatId) else {
            throw ChatRoomErrorEntity.noChatRoomFound
        }
        
        return await withTaskGroup(
            of: [HandleEntity: String]?.self,
            returning: [HandleEntity: String].self
        ) { group in
            for peerId in chatRoom.peers.map(\.handle) {
                group.addTask {
                    if let displayName = chatRoomRepo.contactEmail(forUserHandle: peerId) {
                        return [peerId: displayName]
                    } else {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [HandleEntity: String]()){ result, handleEntityEmailPair in
                if let handleEntityEmailPair {
                    for (key, value) in handleEntityEmailPair {
                        result[key] = value
                    }
                }
            }
        }
    }

    
    public mutating func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomRepo.participantsUpdated(forChatId: chatId)
    }
    
    public mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomRepo.userPrivilegeChanged(forChatId: chatId)
    }
    
    public func ownPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomRepo.ownPrivilegeChanged(forChatId: chatId)
    }
    
    public mutating func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never> {
        if chatRoomRepo.isChatRoomOpen(chatId: chatId) == false {
            try? chatRoomRepo.openChatRoom(chatId: chatId) { _ in }
        }
        
        return chatRoomRepo.allowNonHostToAddParticipantsValueChanged(forChatId: chatId)
    }
    
    public func closeChatRoomPreview(chatRoom: ChatRoomEntity) {
        chatRoomRepo.closeChatRoomPreview(chatRoom: chatRoom)
    }

    public func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool {
        await chatRoomRepo.leaveChatRoom(chatRoom: chatRoom)
    }
    
    public func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) {
        chatRoomRepo.updateChatPrivilege(chatRoom: chatRoom, userHandle: userHandle, privilege: privilege)
    }
    
    public func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        chatRoomRepo.invite(toChat: chat, userId: userId)
    }
    
    public func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) {
        chatRoomRepo.remove(fromChat: chat, userId: userId)
    }
}
