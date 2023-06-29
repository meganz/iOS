import Combine
@testable import MEGA
import MEGADomain

struct MockChatRoomUseCase: ChatRoomUseCaseProtocol {
    var publicLinkCompletion: Result<String, ChatLinkErrorEntity> = .failure(.generic)
    var createChatRoomCompletion: Result<ChatRoomEntity, ChatRoomErrorEntity>?
    var chatRoomEntity: ChatRoomEntity?
    var renameChatRoomCompletion: Result<String, ChatRoomErrorEntity> = .failure(.generic)
    var myPeerHandles: [HandleEntity] = []
    var participantsUpdatedSubject = PassthroughSubject<[HandleEntity], Never>()
    var privilegeChangedSubject = PassthroughSubject<HandleEntity, Never>()
    var peerPrivilege: ChatRoomPrivilegeEntity = .unknown
    var allowNonHostToAddParticipantsEnabled = false
    var chatHasBeenArchived = false
    var allowNonHostToAddParticipantsValueChangedSubject = PassthroughSubject<Bool, Never>()
    var userStatusEntity = ChatStatusEntity.invalid
    var message: ChatMessageEntity?
    var contactEmail: String?
    var base64Handle: String?
    var messageSeenChatId: ((ChatIdEntity) -> Void)?
    var archivedChatId: ((ChatIdEntity, Bool) -> Void)?
    var closePreviewChatId: ((ChatIdEntity) -> Void)?
    var leaveChatRoomSuccess = false
    var ownPrivilegeChangedSubject = PassthroughSubject<HandleEntity, Never>()
    var updatedChatPrivilege: ((HandleEntity, ChatRoomPrivilegeEntity) -> Void)?
    var invitedToChat: ((HandleEntity) -> Void)?
    var removedFromChat: ((HandleEntity) -> Void)?
    var chatSourceEntity: ChatSourceEntity = .error
    var chatMessageLoadedSubject = PassthroughSubject<ChatMessageEntity?, Never>()
    var chatMessageScheduledMeetingChange: ChatMessageScheduledMeetingChangeType = .none
    
    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func chatRoom(forChatId chatId: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity? {
        peerPrivilege
    }

    func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity] {
        myPeerHandles
    }
    
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        if let completionBlock = createChatRoomCompletion {
            completion(completionBlock)
        }
    }
    
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
        completion(publicLinkCompletion)
    }
    
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomCompletion)
    }
    
    func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        participantsUpdatedSubject.eraseToAnyPublisher()
    }
    
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        userStatusEntity
    }
    
    func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        message
    }
    
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity) {
        archivedChatId?(chatRoom.chatId, archive)
    }
    
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity) async throws -> Bool {
        chatHasBeenArchived
    }
    
    func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) {
        messageSeenChatId?(chatRoom.chatId)
    }
    
    func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String? {
        base64Handle
    }
    
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        contactEmail
    }
    
    func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        privilegeChangedSubject.eraseToAnyPublisher()
    }
    
    func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        allowNonHostToAddParticipantsEnabled
    }
    
    func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        allowNonHostToAddParticipantsValueChangedSubject.eraseToAnyPublisher()
    }
    
    func closeChatRoomPreview(chatRoom: ChatRoomEntity) {
        closePreviewChatId?(chatRoom.chatId)
    }
    
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool {
        leaveChatRoomSuccess
    }
    
    func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        ownPrivilegeChangedSubject.eraseToAnyPublisher()
    }
    
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) {
        updatedChatPrivilege?(userHandle, privilege)
    }
    
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        invitedToChat?(userId)
    }
    
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) {
        removedFromChat?(userId)
    }
    
    func loadMessages(for chatRoom: ChatRoomEntity, count: Int) -> ChatSourceEntity {
        chatSourceEntity
    }
    
    func chatMessageLoaded(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatMessageEntity?, Never> {
        chatMessageLoadedSubject.eraseToAnyPublisher()
    }
    
    func closeChatRoom(_ chatRoom: ChatRoomEntity) {    }
    
    func hasScheduledMeetingChange(_ change: ChatMessageScheduledMeetingChangeType, for message: ChatMessageEntity, inChatRoom chatRoom: ChatRoomEntity) -> Bool {
        change == chatMessageScheduledMeetingChange
    }
}
