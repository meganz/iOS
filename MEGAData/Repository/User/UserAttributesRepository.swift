
final class UserAttributesRepository: NSObject, UserAttributesRepositoryProtocol {
    
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()

    func loadUserAttributes(in chatId: MEGAHandle, for userHandles: [NSNumber], completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        chatSdk.loadUserAttributes(forChatId: chatId, usersHandles: userHandles, delegate: MEGAChatGenericRequestDelegate(completion: { (request, error) in
            if error.type == .MEGAChatErrorTypeOk {
                guard let chatRoom = self.chatSdk.chatRoom(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                completion(.success(ChatRoomEntity(with: chatRoom)))
            } else {
                completion(.failure(.generic))
            }
        }))
    }
}
