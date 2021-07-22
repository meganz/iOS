@testable import MEGA

struct MockChatRoomUseCase: ChatRoomUseCaseProtocol {
    var userDisplayNameCompletion: Result<String, Error> = .success("")
    var publicLinkCompletion: Result<String, ChatLinkError> = .failure(.generic)
    var createChatRoomCompletion: Result<ChatRoomEntity, Error>?
    var chatRoomEntity: ChatRoomEntity?
    var renameChatRoomCompletion: Result<String, ChatRoomErrorEntity> = .success("")

    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func chatRoom(forChatId chatId: UInt64) -> ChatRoomEntity? {
        return chatRoomEntity
    }
    
    func createChatRoom(forUserHandle userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, Error>) -> Void) {
        if let completionBlock = createChatRoomCompletion {
            completion(completionBlock)
        }
    }
    
    func fetchPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkError>) -> Void) {
        completion(publicLinkCompletion)
    }
    
    func userDisplayName(forPeerId peerId: UInt64, chatId: UInt64, completion: @escaping (Result<String, Error>) -> Void) {
        completion(userDisplayNameCompletion)
    }
    
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        completion(renameChatRoomCompletion)
    }
}
