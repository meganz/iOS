import Combine
import MEGASwift

public protocol ChatRoomRepositoryProtocol: RepositoryProtocol, Sendable {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func createPublicLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String
    func queryChatLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String) async throws -> String
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity)
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity) async throws -> Bool
    func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity)
    func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String?
    func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool
    func waitingRoom(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool
    func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never>
    func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatRoomEntity, Never> 
    func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never>
    func waitingRoomValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never>
    func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity?
    func isChatRoomOpen(_ chatRoom: ChatRoomEntity) -> Bool
    func openChatRoom(_ chatRoom: ChatRoomEntity, delegate: ChatRoomDelegateEntity) throws
    func closeChatRoom(_ chatRoom: ChatRoomEntity, delegate: ChatRoomDelegateEntity)
    func closeChatRoomPreview(chatRoom: ChatRoomEntity)
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) async throws -> ChatRoomPrivilegeEntity
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity)
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity)
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) async throws
    func loadMessages(forChat chat: ChatRoomEntity, count: Int) -> ChatSourceEntity
    func chatRoomMessageLoaded(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatMessageEntity?, Never>
    func userEmail(for handle: HandleEntity) async -> String?
    func requestLastGreen(for user: HandleEntity)
    var chatConnectionStateUpdate: AnyAsyncSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus)> { get }
    var chatOnlineStatusUpdate: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> { get }
    var presenceLastGreenUpdates: AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> { get }
}
