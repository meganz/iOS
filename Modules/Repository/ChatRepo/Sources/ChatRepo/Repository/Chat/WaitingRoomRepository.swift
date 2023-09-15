import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class WaitingRoomRepository: WaitingRoomRepositoryProtocol {
    private let chatSdk: MEGAChatSdk
    
    public static var newRepo: WaitingRoomRepository {
        WaitingRoomRepository(chatSdk: .sharedChatSdk)
    }
    
    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func userName() -> String {
        chatSdk.myFullname ?? ""
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity {
        return try await withAsyncThrowingValue { result in
            let delegate = ChatRequestDelegate { [weak self] completion in
                switch completion {
                case .success(let request):
                    guard let self, let megaChatRoom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                        result(.failure(CallErrorEntity.generic))
                        return
                    }
                    
                    let chatRoom = megaChatRoom.toChatRoomEntity()
                    result(.success(chatRoom))
                case .failure:
                    result(.failure(CallErrorEntity.generic))
                }
            }
            
            if let megaChatRoom = chatSdk.chatRoom(forChatId: chatId),
               !megaChatRoom.isPreview,
               !megaChatRoom.isActive {
                chatSdk.autorejoinPublicChat(chatId, publicHandle: userHandle, delegate: delegate)
            } else {
                chatSdk.autojoinPublicChat(chatId, delegate: delegate)
            }
        }

    }
}
