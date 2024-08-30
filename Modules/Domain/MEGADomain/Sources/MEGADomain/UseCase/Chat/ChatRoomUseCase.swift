import Combine
import MEGASwift

public protocol ChatRoomUseCaseProtocol: Sendable {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String) async throws -> String
    func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool
    func waitingRoom(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool
    func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity?
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity)
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity) async throws -> Bool
    func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity)
    func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String?
    mutating func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never>
    func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatRoomEntity, Never>
    mutating func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    mutating func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never>
    mutating func waitingRoomValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never>
    func closeChatRoomPreview(chatRoom: ChatRoomEntity)
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity)
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) async throws -> ChatRoomPrivilegeEntity
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity)
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity)
    func loadMessages(for chatRoom: ChatRoomEntity, count: Int) -> ChatSourceEntity
    func chatMessageLoaded(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatMessageEntity?, Never>
    func closeChatRoom(_ chatRoom: ChatRoomEntity)
    func hasScheduledMeetingChange(_ change: ChatMessageScheduledMeetingChangeType, for message: ChatMessageEntity, inChatRoom chatRoom: ChatRoomEntity) -> Bool
    func shouldOpenWaitingRoom(forChatId chatId: HandleEntity) -> Bool
    func userEmail(for handle: HandleEntity) async -> String?
    func monitorOnChatConnectionStateUpdate() -> AnyAsyncThrowingSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus), any Error>
}

public struct ChatRoomUseCase<T: ChatRoomRepositoryProtocol>: ChatRoomUseCaseProtocol, Sendable {
    private var chatRoomRepo: T
    
    public init(chatRoomRepo: T) {
        self.chatRoomRepo = chatRoomRepo
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
    
    public func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity {
        chatRoomRepo.peerPrivilege(forUserHandle: userHandle, chatRoom: chatRoom)
    }
    
    public func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        chatRoomRepo.userStatus(forUserHandle: userHandle)
    }
    
    public func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String {
        if chatRoom.chatType == .oneToOne {
            // Not allowed to create/query chat link
            throw ChatLinkErrorEntity.creatingChatLinkNotAllowed
        }
        
        if chatRoom.ownPrivilege == .moderator {
            do {
                return try await chatRoomRepo.queryChatLink(forChatRoom: chatRoom)
            } catch ChatLinkErrorEntity.resourceNotFound {
                return try await chatRoomRepo.createPublicLink(forChatRoom: chatRoom)
            } catch {
                throw error
            }
        } else {
            return try await chatRoomRepo.queryChatLink(forChatRoom: chatRoom)
        }
    }

    public func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        chatRoomRepo.renameChatRoom(chatRoom, title: title, completion: completion)
    }
    
    public func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String) async throws -> String {
        try await chatRoomRepo.renameChatRoom(chatRoom, title: title)
    }
    
    public func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        try await chatRoomRepo.allowNonHostToAddParticipants(enabled, forChatRoom: chatRoom)
    }
    
    public func waitingRoom(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        try await chatRoomRepo.waitingRoom(enabled, forChatRoom: chatRoom)
    }
    
    public func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        chatRoomRepo.message(forChatRoom: chatRoom, messageId: messageId)
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) {
        chatRoomRepo.archive(archive, chatRoom: chatRoom)
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) async throws -> Bool {
        try await chatRoomRepo.archive(archive, chatRoom: chatRoom)
    }
    
    public func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) {
        chatRoomRepo.setMessageSeenForChat(forChatRoom: chatRoom, messageId: messageId)
    }
    
    public func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String? {
        chatRoomRepo.base64Handle(forChatRoom: chatRoom)
    }
    
    public mutating func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomRepo.participantsUpdated(forChatRoom: chatRoom)
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatRoomEntity, Never> {
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
            try? chatRoomRepo.openChatRoom(chatRoom, delegate: ChatRoomDelegateEntity())
        }
        
        return chatRoomRepo.allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
    }
    
    public func waitingRoomValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        if chatRoomRepo.isChatRoomOpen(chatRoom) == false {
            try? chatRoomRepo.openChatRoom(chatRoom, delegate: ChatRoomDelegateEntity())
        }
        
        return chatRoomRepo.waitingRoomValueChanged(forChatRoom: chatRoom)
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
    
    public func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) async throws -> ChatRoomPrivilegeEntity {
        try await chatRoomRepo.updateChatPrivilege(chatRoom: chatRoom, userHandle: userHandle, privilege: privilege)
    }
    
    public func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        chatRoomRepo.invite(toChat: chat, userId: userId)
    }
    
    public func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) {
        chatRoomRepo.remove(fromChat: chat, userId: userId)
    }
    
    public func chatMessageLoaded(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatMessageEntity?, Never> {
        if chatRoomRepo.isChatRoomOpen(chatRoom) == false {
            try? chatRoomRepo.openChatRoom(chatRoom, delegate: ChatRoomDelegateEntity())
        }
        
        return chatRoomRepo.chatRoomMessageLoaded(forChatRoom: chatRoom)
    }
    
    public func loadMessages(for chatRoom: ChatRoomEntity, count: Int) -> ChatSourceEntity {
        chatRoomRepo.loadMessages(forChat: chatRoom, count: count)
    }
    
    public func closeChatRoom(_ chatRoom: ChatRoomEntity) {
        if chatRoomRepo.isChatRoomOpen(chatRoom) {
            chatRoomRepo.closeChatRoom(chatRoom, delegate: ChatRoomDelegateEntity())
        }
    }
    
    public func hasScheduledMeetingChange(_ change: ChatMessageScheduledMeetingChangeType, for message: ChatMessageEntity, inChatRoom chatRoom: ChatRoomEntity) -> Bool {
        chatRoomRepo.hasScheduledMeetingChange(change, for: message, inChatRoom: chatRoom)
    }
    
    public func shouldOpenWaitingRoom(forChatId chatId: HandleEntity) -> Bool {
        guard let chatRoom = chatRoomRepo.chatRoom(forChatId: chatId) else { return false }
        let isModerator = chatRoom.ownPrivilege == .moderator
        return !isModerator && chatRoom.isWaitingRoomEnabled
    }
    
    public func userEmail(for handle: HandleEntity) async -> String? {
        await chatRoomRepo.userEmail(for: handle)
    }

    public func monitorOnChatConnectionStateUpdate() -> AnyAsyncThrowingSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus), any Error> {
        chatRoomRepo.chatConnectionStateUpdate
            .eraseToAnyAsyncThrowingSequence()
    }
}
