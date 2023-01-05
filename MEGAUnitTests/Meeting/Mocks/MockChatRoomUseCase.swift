@testable import MEGA
import Combine
import MEGADomain

struct MockChatRoomUseCase: ChatRoomUseCaseProtocol {
    
    var userDisplayNameCompletion: Result<String, ChatRoomErrorEntity> = .failure(.generic)
    var userDisplayNamesCompletion: Result<[(handle: HandleEntity, name: String)], ChatRoomErrorEntity> = .failure(.generic)
    var publicLinkCompletion: Result<String, ChatLinkErrorEntity> = .failure(.generic)
    var createChatRoomCompletion: Result<ChatRoomEntity, ChatRoomErrorEntity>?
    var chatRoomEntity: ChatRoomEntity?
    var renameChatRoomCompletion: Result<String, ChatRoomErrorEntity> = .failure(.generic)
    var myPeerHandles: [HandleEntity] = []
    var participantsUpdatedSubject = PassthroughSubject<[HandleEntity], Never>()
    var privilegeChangedSubject = PassthroughSubject<HandleEntity, Never>()
    var peerPrivilege: ChatRoomPrivilegeEntity = .unknown
    var allowNonHostToAddParticipantsEnabled = false
    var allowNonHostToAddParticipantsValueChangedSubject = PassthroughSubject<Bool, Never>()
    var userStatusEntity = ChatStatusEntity.invalid
    var message: ChatMessageEntity? = nil
    var contactEmail: String? = nil
    var base64Handle: String? = nil
    var messageSeenChatId: ((ChatIdEntity) -> Void)? = nil
    var archivedChatId: ((ChatIdEntity, Bool) -> Void)? = nil
    var userFullNames: [String] = []
    var userNickNames: [HandleEntity : String] = [:]
    var userEmails:  [HandleEntity : String] = [:]
    var closePreviewChatId: ((ChatIdEntity) -> Void)? = nil
    var leaveChatRoomSuccess = false
    var ownPrivilegeChangedSubject = PassthroughSubject<HandleEntity, Never>()
    var updatedChatPrivilege: ((HandleEntity, ChatRoomPrivilegeEntity) -> Void)? = nil
    var invitedToChat: ((HandleEntity) -> Void)? = nil
    var removedFromChat: ((HandleEntity) -> Void)? = nil

    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func chatRoom(forChatId chatId: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomPrivilegeEntity? {
        peerPrivilege
    }

    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity] {
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
    
    func userDisplayName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(userDisplayNameCompletion)
    }
    
    func userDisplayNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String] {
        switch userDisplayNamesCompletion {
        case .success(let handleNamePairArray):
            return peerIds.compactMap { handle in
                return handleNamePairArray.first(where: { $0.handle == handle })?.name
            }
        case .failure(let error):
            throw error
        }
    }
    
    func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomCompletion)
    }
    
    func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never> {
        participantsUpdatedSubject.eraseToAnyPublisher()
    }
    
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        userStatusEntity
    }
    
    func message(forChatId chatId: ChatIdEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        message
    }
    
    func archive(_ archive: Bool, chatId: ChatIdEntity) {
        archivedChatId?(chatId, archive)
    }
    
    func setMessageSeenForChat(forChatId chatId: ChatIdEntity, messageId: HandleEntity) {
        messageSeenChatId?(chatId)
    }
    
    func base64Handle(forChatId chatId: ChatIdEntity) -> String? {
        base64Handle
    }
    
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        contactEmail
    }
    
    func userFullNames(forPeerIds peerIds: [HandleEntity], chatId: HandleEntity) async throws -> [String] {
        userFullNames
    }
    
    func userNickNames(forChatId chatId: ChatIdEntity) async throws -> [HandleEntity : String] {
        userNickNames
    }
    
    func userEmails(forChatId chatId: ChatIdEntity) async throws -> [HandleEntity : String] {
        userEmails
    }
    
    mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        privilegeChangedSubject.eraseToAnyPublisher()
    }
    
    func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool {
        allowNonHostToAddParticipantsEnabled
    }
    
    mutating func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never> {
        allowNonHostToAddParticipantsValueChangedSubject.eraseToAnyPublisher()
    }
    
    func closeChatRoomPreview(chatRoom: ChatRoomEntity) {
        closePreviewChatId?(chatRoom.chatId)
    }
    
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool {
        leaveChatRoomSuccess
    }
    
    func ownPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        ownPrivilegeChangedSubject.eraseToAnyPublisher()
    }
    
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) {
        updatedChatPrivilege?(userHandle, privilege)
    }
    
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        invitedToChat?(userId)
    }
    
    func remove(fromChat chat: MEGADomain.ChatRoomEntity, userId: HandleEntity) {
        removedFromChat?(userId)
    }
}
