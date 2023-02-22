import Combine

public protocol ChatRoomUseCaseProtocol {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity?
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userDisplayName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatRoom: ChatRoomEntity) async throws -> [String]
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool
    func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity?
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity)
    func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity,  messageId: HandleEntity)
    func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String?
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String?
    func userFullNames(forPeerIds peerIds: [HandleEntity], chatRoom: ChatRoomEntity) async throws -> [String]
    func userNickNames(forChatRoom chatRoom: ChatRoomEntity) async throws -> [HandleEntity: String]
    func userEmails(forChatRoom chatRoom: ChatRoomEntity) async throws -> [HandleEntity: String]
    mutating func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never>
    mutating func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    mutating func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never>
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
    
    public func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity] {
        chatRoomRepo.peerHandles(forChatRoom: chatRoom)
    }
    
    public func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity? {
        chatRoomRepo.peerPrivilege(forUserHandle: userHandle, chatRoom: chatRoom)
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
            chatRoomRepo.queryChatLink(forChatRoom: chatRoom) { result in
                // If the user is a moderator and the link is not generated yet. Generate the link.
                if case let .failure(error) = result, error == .resourceNotFound {
                    chatRoomRepo.createPublicLink(forChatRoom: chatRoom, completion: completion)
                } else {
                    completion(result)
                }
            }
        } else {
            chatRoomRepo.queryChatLink(forChatRoom: chatRoom, completion: completion)
        }
    }
    
    public func userDisplayName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        if let displayName = userStoreRepo.getDisplayName(forUserHandle: peerId) {
            completion(.success(displayName))
            return
        }

        chatRoomRepo.userFullName(forPeerId: peerId, chatRoom: chatRoom, completion: completion)
    }
    
    public func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatRoom: ChatRoomEntity) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for peerId in peerIds {
                group.addTask {
                    if let nickName = await userStoreRepo.displayName(forUserHandle: peerId) {
                        return nickName
                    }
                    
                    return try await chatRoomRepo.userFullName(forPeerId: peerId, chatRoom: chatRoom)
                }
            }
                        
            return try await group.reduce(into: [String]()) { result, name in
                result.append(name)
            }
        }
    }

    public func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.renameChatRoom(chatRoom, title: title, completion: completion)
    }
    
    public func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        try await chatRoomRepo.allowNonHostToAddParticipants(enabled, forChatRoom: chatRoom)
    }
    
    public func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        chatRoomRepo.message(forChatRoom: chatRoom, messageId: messageId)
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) {
        chatRoomRepo.archive(archive, chatRoom: chatRoom)
    }
    
    public func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity,  messageId: HandleEntity) {
        chatRoomRepo.setMessageSeenForChat(forChatRoom: chatRoom, messageId: messageId)
    }
    
    public func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String? {
        chatRoomRepo.base64Handle(forChatRoom: chatRoom)
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        chatRoomRepo.contactEmail(forUserHandle: userHandle)
    }
    
    public func userFullNames(forPeerIds peerIds: [HandleEntity], chatRoom: ChatRoomEntity) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for peerId in peerIds {
                group.addTask { try await chatRoomRepo.userFullName(forPeerId: peerId, chatRoom: chatRoom) }
            }
                        
            return try await group.reduce(into: [String]()) { result, name in
                result.append(name)
            }
        }
    }
    
    public func userNickNames(forChatRoom chatRoom: ChatRoomEntity) async throws -> [HandleEntity: String] {
        await withTaskGroup(
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
    
    public func userEmails(forChatRoom chatRoom: ChatRoomEntity) async throws -> [HandleEntity: String] {
        await withTaskGroup(
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

    
    public mutating func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomRepo.participantsUpdated(forChatRoom: chatRoom)
    }
    
    public mutating func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomRepo.userPrivilegeChanged(forChatRoom: chatRoom)
    }
    
    public func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomRepo.ownPrivilegeChanged(forChatRoom: chatRoom)
    }
    
    public mutating func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        if chatRoomRepo.isChatRoomOpen(chatRoom) == false {
            try? chatRoomRepo.openChatRoom(chatRoom) { _ in }
        }
        
        return chatRoomRepo.allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
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
