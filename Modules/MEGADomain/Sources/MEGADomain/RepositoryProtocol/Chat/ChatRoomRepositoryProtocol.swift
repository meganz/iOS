import Combine

public protocol ChatRoomRepositoryProtocol {
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity?
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity?
    func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity]
    func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity?
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void)
    func createPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func queryChatLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void)
    func userFullName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func userFullName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity) async throws -> String
    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void)
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity)
    func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity,  messageId: HandleEntity)
    func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String?
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String?
    func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool
    func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never>
    func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never>
    func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never>
    func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity?
    func isChatRoomOpen(_ chatRoom: ChatRoomEntity) -> Bool
    func openChatRoom(_ chatRoom: ChatRoomEntity, callback:  @escaping (ChatRoomCallbackEntity) -> Void) throws
    func closeChatRoom(_ chatRoom: ChatRoomEntity, callback:  @escaping (ChatRoomCallbackEntity) -> Void)
    func closeChatRoomPreview(chatRoom: ChatRoomEntity)
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity)
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity)
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity)
}
