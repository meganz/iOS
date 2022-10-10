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
    
    mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        privilegeChangedSubject.eraseToAnyPublisher()
    }
    
    func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool {
        allowNonHostToAddParticipantsEnabled
    }
    
    mutating func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never> {
        allowNonHostToAddParticipantsValueChangedSubject.eraseToAnyPublisher()
    }
}
