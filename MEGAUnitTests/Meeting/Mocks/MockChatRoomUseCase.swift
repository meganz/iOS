@testable import MEGA

struct MockChatRoomUseCase: ChatRoomUseCaseProtocol {
    var userDisplayNameCompletion: Result<String, Error> = .success("")
    var publicLinkCompletion: Result<String, ChatLinkErrorEntity> = .failure(.generic)
    var createChatRoomCompletion: Result<ChatRoomEntity, ChatRoomErrorEntity>?
    var chatRoomEntity: ChatRoomEntity?
    var renameChatRoomCompletion: Result<String, ChatRoomErrorEntity> = .success("")

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
    
    func userDisplayName(forPeerId peerId: MEGAHandle, chatId: MEGAHandle, completion: @escaping (Result<String, Error>) -> Void) {
        completion(userDisplayNameCompletion)
    }
    
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomCompletion)
    }
}
