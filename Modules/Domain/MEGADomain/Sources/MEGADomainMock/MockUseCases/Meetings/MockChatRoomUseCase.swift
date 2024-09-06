@preconcurrency import Combine
import MEGADomain
import MEGASwift

public struct MockChatRoomUseCase: ChatRoomUseCaseProtocol, @unchecked Sendable {
    private let publicLinkCompletion: Result<String, ChatLinkErrorEntity>
    var createChatRoomCompletion: Result<ChatRoomEntity, ChatRoomErrorEntity>?
    private let chatRoomEntity: ChatRoomEntity?
    var renameChatRoomCompletion: Result<String, ChatRoomErrorEntity> = .failure(.generic)
    private let myPeerHandles: [HandleEntity]
    var participantsUpdatedSubject = PassthroughSubject<[HandleEntity], Never>()
    private let participantsUpdatedSubjectWithChatRoom: PassthroughSubject<ChatRoomEntity, Never>
    var privilegeChangedSubject = PassthroughSubject<HandleEntity, Never>()
    private let peerPrivilege: ChatRoomPrivilegeEntity
    private let allowNonHostToAddParticipantsEnabled: Bool
    private let waitingRoomEnabled: Bool
    var chatHasBeenArchived = false
    public let allowNonHostToAddParticipantsValueChangedSubject = PassthroughSubject<Bool, Never>()
    var waitingRoomValueChangedSubject = PassthroughSubject<Bool, Never>()
    public let userStatusEntity: ChatStatusEntity
    private let message: ChatMessageEntity?
    private let contactEmail: String?
    var base64Handle: String?
    var messageSeenChatId: ((ChatIdEntity) -> Void)?
    var archivedChatId: ((ChatIdEntity, Bool) -> Void)?
    var closePreviewChatId: ((ChatIdEntity) -> Void)?
    var leaveChatRoomSuccess = false
    var ownPrivilegeChangedSubject = PassthroughSubject<HandleEntity, Never>()
    var updatedChatPrivilege: ((HandleEntity, ChatRoomPrivilegeEntity) -> Void)?
    private let updatedChatPrivilegeResult: Result<ChatRoomPrivilegeEntity, ChatRoomErrorEntity>
    private let invitedToChat: ((HandleEntity) -> Void)?
    var removedFromChat: ((HandleEntity) -> Void)?
    var chatSourceEntity: ChatSourceEntity = .error
    var chatMessageLoadedSubject = PassthroughSubject<ChatMessageEntity?, Never>()
    var chatMessageScheduledMeetingChange: ChatMessageScheduledMeetingChangeType = .none
    private let shouldOpenWaitRoom: Bool
    private let monitorChatConnectionStateUpdate: AnyAsyncThrowingSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus), any Error>

    public init(
        chatRoomEntity: ChatRoomEntity? = nil,
        peerPrivilege: ChatRoomPrivilegeEntity = .unknown,
        invitedToChat: ((HandleEntity) -> Void)? = nil,
        updatedChatPrivilegeResult: Result<ChatRoomPrivilegeEntity, ChatRoomErrorEntity> = .failure(.generic),
        myPeerHandles: [HandleEntity] = [],
        message: ChatMessageEntity? = nil,
        shouldOpenWaitRoom: Bool = true,
        publicLinkCompletion: Result<String, ChatLinkErrorEntity> = .failure(.generic),
        allowNonHostToAddParticipantsEnabled: Bool = false,
        waitingRoomEnabled: Bool = false,
        contactEmail: String? = nil,
        participantsUpdatedSubjectWithChatRoom: PassthroughSubject<ChatRoomEntity, Never> = PassthroughSubject<ChatRoomEntity, Never>(),
        userStatusEntity: ChatStatusEntity = ChatStatusEntity.invalid,
        monitorChatConnectionStateUpdate: AnyAsyncThrowingSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus), any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    ) {
        self.chatRoomEntity = chatRoomEntity
        self.peerPrivilege = peerPrivilege
        self.invitedToChat = invitedToChat
        self.updatedChatPrivilegeResult = updatedChatPrivilegeResult
        self.myPeerHandles = myPeerHandles
        self.message = message
        self.shouldOpenWaitRoom = shouldOpenWaitRoom
        self.publicLinkCompletion = publicLinkCompletion
        self.allowNonHostToAddParticipantsEnabled = allowNonHostToAddParticipantsEnabled
        self.waitingRoomEnabled = waitingRoomEnabled
        self.contactEmail = contactEmail
        self.participantsUpdatedSubjectWithChatRoom = participantsUpdatedSubjectWithChatRoom
        self.userStatusEntity = userStatusEntity
        self.monitorChatConnectionStateUpdate = monitorChatConnectionStateUpdate
    }
    
    public func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        chatRoomEntity
    }
    
    public func chatRoom(forChatId chatId: UInt64) -> ChatRoomEntity? {
        chatRoomEntity
    }
    
    public func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity {
        peerPrivilege
    }

    public func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity] {
        myPeerHandles
    }
    
    public func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        if let completionBlock = createChatRoomCompletion {
            completion(completionBlock)
        }
    }
    
    public func fetchPublicLink(forChatRoom chatRoom: MEGADomain.ChatRoomEntity) async throws -> String {
        switch publicLinkCompletion {
        case .success(let link):
            return link
        case .failure(let error):
            throw error
        }
    }
    
    public func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomCompletion)
    }
    
    public func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String) async throws -> String {
        switch renameChatRoomCompletion {
        case .success(let newName):
            return newName
        case .failure(let failure):
            throw failure
        }
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        participantsUpdatedSubject.eraseToAnyPublisher()
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        participantsUpdatedSubjectWithChatRoom.eraseToAnyPublisher()
    }
    
    public func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        userStatusEntity
    }
    
    public func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        message
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) {
        archivedChatId?(chatRoom.chatId, archive)
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) async throws -> Bool {
        chatHasBeenArchived
    }
    
    public func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) {
        messageSeenChatId?(chatRoom.chatId)
    }
    
    public func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String? {
        base64Handle
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        contactEmail
    }
    
    public func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        privilegeChangedSubject.eraseToAnyPublisher()
    }
    
    public func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        allowNonHostToAddParticipantsEnabled
    }
    
    public func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        allowNonHostToAddParticipantsValueChangedSubject.eraseToAnyPublisher()
    }
    
    public func waitingRoom(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        waitingRoomEnabled
    }
    
    mutating public func waitingRoomValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        waitingRoomValueChangedSubject.eraseToAnyPublisher()
    }
    
    public func closeChatRoomPreview(chatRoom: ChatRoomEntity) {
        closePreviewChatId?(chatRoom.chatId)
    }
    
    public func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool {
        leaveChatRoomSuccess
    }
    
    public func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        ownPrivilegeChangedSubject.eraseToAnyPublisher()
    }
    
    public func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) {
        updatedChatPrivilege?(userHandle, privilege)
    }
    
    public func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) async throws -> ChatRoomPrivilegeEntity {
        switch updatedChatPrivilegeResult {
        case .success(let privilege):
            return privilege
        case .failure(let error):
            throw error
        }
    }
    
    public func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        invitedToChat?(userId)
    }
    
    public func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) {
        removedFromChat?(userId)
    }
    
    public func loadMessages(for chatRoom: ChatRoomEntity, count: Int) -> ChatSourceEntity {
        chatSourceEntity
    }
    
    public func chatMessageLoaded(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatMessageEntity?, Never> {
        chatMessageLoadedSubject.eraseToAnyPublisher()
    }
    
    public func closeChatRoom(_ chatRoom: ChatRoomEntity) {    }
    
    public func hasScheduledMeetingChange(_ change: ChatMessageScheduledMeetingChangeType, for message: ChatMessageEntity, inChatRoom chatRoom: ChatRoomEntity) -> Bool {
        change == chatMessageScheduledMeetingChange
    }
    
    public func shouldOpenWaitingRoom(forChatId chatId: HandleEntity) -> Bool {
        shouldOpenWaitRoom
    }
    
    public func userEmail(for handle: HandleEntity) async -> String? {
        contactEmail
    }
    
    public func monitorOnChatConnectionStateUpdate() -> AnyAsyncThrowingSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus), any Error> {
        monitorChatConnectionStateUpdate.eraseToAnyAsyncThrowingSequence()
    }
}
