import Combine
import MEGADomain

public final class MockChatRoomRepository: ChatRoomRepositoryProtocol {
    public static var newRepo: MockChatRoomRepository = MockChatRoomRepository()
    
    private let chatRoom: ChatRoomEntity?
    private let peerHandles: [MEGADomain.HandleEntity]
    private let peerPrivilege: MEGADomain.ChatRoomPrivilegeEntity
    private let userStatus: MEGADomain.ChatStatusEntity
    private let createChatRoomResult: Result<MEGADomain.ChatRoomEntity, MEGADomain.ChatRoomErrorEntity>
    private let createPublicLinkResult: Result<String, MEGADomain.ChatLinkErrorEntity>
    private let queryChatLinkResult: Result<String, MEGADomain.ChatLinkErrorEntity>
    private let renameChatRoomResult: Result<String, MEGADomain.ChatRoomErrorEntity>
    private let base64Handle: String?
    private let participantsUpdatedPublisher: AnyPublisher<[HandleEntity], Never>
    private let participantsUpdatedPublisherWithChatRoom: AnyPublisher<ChatRoomEntity, Never>
    private let userPrivilegeChangedPublisher: AnyPublisher<MEGADomain.HandleEntity, Never>
    private let ownPrivilegeChangedPublisher: AnyPublisher<MEGADomain.HandleEntity, Never>
    private let allowNonHostToAddParticipantsValueChangedPublisher: AnyPublisher<Bool, Never>
    private let waitingRoomValueChangedPublisher: AnyPublisher<Bool, Never>
    private let message: MEGADomain.ChatMessageEntity?
    private let isChatRoomOpen: Bool
    private let leaveChatRoom: Bool
    private let updateChatPrivilegeResult: Result<ChatRoomPrivilegeEntity, ChatRoomErrorEntity>
    private let loadMessages: MEGADomain.ChatSourceEntity
    private let chatRoomMessageLoadedPublisher: AnyPublisher<MEGADomain.ChatMessageEntity?, Never>
    private let hasScheduledMeetingChange: Bool
    private let userEmail: String?

    public init(
        chatRoom: ChatRoomEntity? = nil,
        peerHandles: [MEGADomain.HandleEntity] = [],
        peerPrivilege: MEGADomain.ChatRoomPrivilegeEntity = .unknown,
        userStatus: MEGADomain.ChatStatusEntity = .online,
        createChatRoomResult: Result<MEGADomain.ChatRoomEntity, MEGADomain.ChatRoomErrorEntity> = .failure(.generic),
        createPublicLinkResult: Result<String, MEGADomain.ChatLinkErrorEntity> = .failure(.generic),
        queryChatLinkResult: Result<String, MEGADomain.ChatLinkErrorEntity> = .failure(.generic),
        renameChatRoomResult: Result<String, MEGADomain.ChatRoomErrorEntity> = .failure(.generic),
        base64Handle: String? = nil,
        participantsUpdatedPublisher: AnyPublisher<[HandleEntity], Never> = Empty().eraseToAnyPublisher(),
        participantsUpdatedPublisherWithChatRoom: AnyPublisher<ChatRoomEntity, Never> = Empty().eraseToAnyPublisher(),
        userPrivilegeChangedPublisher: AnyPublisher<HandleEntity, Never> = Empty().eraseToAnyPublisher(),
        ownPrivilegeChangedPublisher: AnyPublisher<HandleEntity, Never> = Empty().eraseToAnyPublisher(),
        allowNonHostToAddParticipantsValueChangedPublisher: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
        waitingRoomValueChangedPublisher: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
        message: MEGADomain.ChatMessageEntity? = nil,
        isChatRoomOpen: Bool = true,
        leaveChatRoom: Bool = true,
        updateChatPrivilegeResult: Result<ChatRoomPrivilegeEntity, ChatRoomErrorEntity> = .failure(.generic),
        loadMessages: MEGADomain.ChatSourceEntity = .local,
        chatRoomMessageLoadedPublisher: AnyPublisher<MEGADomain.ChatMessageEntity?, Never> = Empty().eraseToAnyPublisher(),
        hasScheduledMeetingChange: Bool = false,
        userEmail: String? = nil
    ) {
        self.chatRoom = chatRoom
        self.peerHandles = peerHandles
        self.peerPrivilege = peerPrivilege
        self.userStatus = userStatus
        self.createChatRoomResult = createChatRoomResult
        self.createPublicLinkResult = createPublicLinkResult
        self.queryChatLinkResult = queryChatLinkResult
        self.renameChatRoomResult = renameChatRoomResult
        self.base64Handle = base64Handle
        self.participantsUpdatedPublisher = participantsUpdatedPublisher
        self.participantsUpdatedPublisherWithChatRoom = participantsUpdatedPublisherWithChatRoom
        self.userPrivilegeChangedPublisher = userPrivilegeChangedPublisher
        self.ownPrivilegeChangedPublisher = ownPrivilegeChangedPublisher
        self.allowNonHostToAddParticipantsValueChangedPublisher = allowNonHostToAddParticipantsValueChangedPublisher
        self.waitingRoomValueChangedPublisher = waitingRoomValueChangedPublisher
        self.message = message
        self.isChatRoomOpen = isChatRoomOpen
        self.leaveChatRoom = leaveChatRoom
        self.updateChatPrivilegeResult = updateChatPrivilegeResult
        self.loadMessages = loadMessages
        self.chatRoomMessageLoadedPublisher = chatRoomMessageLoadedPublisher
        self.hasScheduledMeetingChange = hasScheduledMeetingChange
        self.userEmail = userEmail
    }
    
    public func chatRoom(forChatId chatId: MEGADomain.HandleEntity) -> MEGADomain.ChatRoomEntity? {
        chatRoom
    }
    
    public func chatRoom(forUserHandle userHandle: MEGADomain.HandleEntity) -> MEGADomain.ChatRoomEntity? {
        chatRoom
    }
    
    public func peerHandles(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> [MEGADomain.HandleEntity] {
        peerHandles
    }
    
    public func peerPrivilege(forUserHandle userHandle: MEGADomain.HandleEntity, chatRoom: MEGADomain.ChatRoomEntity) -> MEGADomain.ChatRoomPrivilegeEntity {
        peerPrivilege
    }
    
    public func userStatus(forUserHandle userHandle: MEGADomain.HandleEntity) -> MEGADomain.ChatStatusEntity {
        userStatus
    }
    
    public func createChatRoom(forUserHandle userHandle: MEGADomain.HandleEntity, completion: @escaping (Result<MEGADomain.ChatRoomEntity, MEGADomain.ChatRoomErrorEntity>) -> Void) {
        completion(createChatRoomResult)
    }
    
    public func createPublicLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String {
        switch createPublicLinkResult {
        case .success(let link):
            return link
        case .failure(let error):
            throw error
        }
    }
    
    public func queryChatLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String {
        switch queryChatLinkResult {
        case .success(let link):
            return link
        case .failure(let error):
            throw error
        }
    }
    
    public func renameChatRoom(_ chatRoom: MEGADomain.ChatRoomEntity, title: String, completion: @escaping (Result<String, MEGADomain.ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomResult)
    }
    
    public func renameChatRoom(_ chatRoom: MEGADomain.ChatRoomEntity, title: String) async throws -> String {
        title
    }
    
    public func archive(_ archive: Bool, chatRoom: MEGADomain.ChatRoomEntity) {
    }
    
    public func archive(_ archive: Bool, chatRoom: MEGADomain.ChatRoomEntity) async throws -> Bool {
        archive
    }
    
    public func setMessageSeenForChat(forChatRoom chatRoom: MEGADomain.ChatRoomEntity, messageId: MEGADomain.HandleEntity) {
    }
    
    public func base64Handle(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> String? {
        base64Handle
    }
    
    public func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: MEGADomain.ChatRoomEntity) async throws -> Bool {
        enabled
    }
    
    public func waitingRoom(_ enabled: Bool, forChatRoom chatRoom: MEGADomain.ChatRoomEntity) async throws -> Bool {
        enabled
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        participantsUpdatedPublisher
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        participantsUpdatedPublisherWithChatRoom
    }
    
    public func userPrivilegeChanged(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> AnyPublisher<MEGADomain.HandleEntity, Never> {
        userPrivilegeChangedPublisher
    }
    
    public func ownPrivilegeChanged(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> AnyPublisher<MEGADomain.HandleEntity, Never> {
        ownPrivilegeChangedPublisher
    }
    
    public func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        allowNonHostToAddParticipantsValueChangedPublisher
    }
    
    public func waitingRoomValueChanged(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        waitingRoomValueChangedPublisher
    }
    
    public func message(forChatRoom chatRoom: MEGADomain.ChatRoomEntity, messageId: MEGADomain.HandleEntity) -> MEGADomain.ChatMessageEntity? {
        message
    }
    
    public func isChatRoomOpen(_ chatRoom: MEGADomain.ChatRoomEntity) -> Bool {
        isChatRoomOpen
    }
    
    public func openChatRoom(_ chatRoom: MEGADomain.ChatRoomEntity, delegate: MEGADomain.ChatRoomDelegateEntity) throws {
    }
    
    public func closeChatRoom(_ chatRoom: MEGADomain.ChatRoomEntity, delegate: MEGADomain.ChatRoomDelegateEntity) {
    }
    
    public func closeChatRoomPreview(chatRoom: MEGADomain.ChatRoomEntity) {
    }
    
    public func leaveChatRoom(chatRoom: MEGADomain.ChatRoomEntity) async -> Bool {
        leaveChatRoom
    }
    
    public func updateChatPrivilege(chatRoom: MEGADomain.ChatRoomEntity, userHandle: MEGADomain.HandleEntity, privilege: MEGADomain.ChatRoomPrivilegeEntity) {
    }
    
    public func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) async throws -> ChatRoomPrivilegeEntity {
        switch updateChatPrivilegeResult {
        case .success(let privilege):
            return privilege
        case .failure(let error):
            throw error
        }
    }
    
    public func invite(toChat chat: MEGADomain.ChatRoomEntity, userId: MEGADomain.HandleEntity) {
    }
    
    public func remove(fromChat chat: MEGADomain.ChatRoomEntity, userId: MEGADomain.HandleEntity) {
    }
    
    public func loadMessages(forChat chat: MEGADomain.ChatRoomEntity, count: Int) -> MEGADomain.ChatSourceEntity {
        loadMessages
    }
    
    public func chatRoomMessageLoaded(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> AnyPublisher<MEGADomain.ChatMessageEntity?, Never> {
        chatRoomMessageLoadedPublisher
    }
    
    public func hasScheduledMeetingChange(_ change: MEGADomain.ChatMessageScheduledMeetingChangeType, for message: MEGADomain.ChatMessageEntity, inChatRoom chatRoom: MEGADomain.ChatRoomEntity) -> Bool {
        hasScheduledMeetingChange
    }
    
    public func userEmail(for handle: MEGADomain.HandleEntity) async -> String? {
        userEmail
    }
}
