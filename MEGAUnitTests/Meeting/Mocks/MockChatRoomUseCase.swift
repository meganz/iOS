@testable import MEGA

struct MockChatRoomUseCase: ChatRoomUseCaseProtocol {
    var userDisplayNameCompletion: Result<String, ChatRoomErrorEntity> = .failure(.generic)
    var userDisplayNamesCompletion: Result<[(handle: MEGAHandle, name: String)], ChatRoomErrorEntity> = .failure(.generic)
    var publicLinkCompletion: Result<String, ChatLinkErrorEntity> = .failure(.generic)
    var createChatRoomCompletion: Result<ChatRoomEntity, ChatRoomErrorEntity>?
    var chatRoomEntity: ChatRoomEntity?
    var renameChatRoomCompletion: Result<String, ChatRoomErrorEntity> = .failure(.generic)

    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func chatRoom(forChatId chatId: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func createChatRoom(forUserHandle userHandle: MEGAHandle, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        if let completionBlock = createChatRoomCompletion {
            completion(completionBlock)
        }
    }
    
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
        completion(publicLinkCompletion)
    }
    
    func userDisplayName(forPeerId peerId: MEGAHandle, chatId: MEGAHandle, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(userDisplayNameCompletion)
    }
    
    func userDisplayNames(forPeerIds peerIds: [MEGAHandle], chatId: MEGAHandle) async throws -> [String] {
        switch userDisplayNamesCompletion {
        case .success(let handleNamePairArray):
            return peerIds.compactMap { handle in
                return handleNamePairArray.filter({ $0.handle == handle }).first?.name
            }
        case .failure(let error):
            throw error
        }
    }
    
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomCompletion)
    }
}
