import Foundation
import MEGAChatSdk
import MEGADomain
import MEGASwift

public struct ChatRoomUserRepository: ChatRoomUserRepositoryProtocol {
    public static var newRepo: ChatRoomUserRepository {
        ChatRoomUserRepository(chatSdk: MEGAChatSdk.sharedChatSdk)
    }
    
    private let chatSdk: MEGAChatSdk
    private init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func userFullName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity) async throws -> String {
        if let name = chatSdk.userFullnameFromCache(byUserHandle: peerId) {
            return name
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = ChatRequestDelegate { result in
                switch result {
                case .success:
                    guard let name = self.chatSdk.userFullnameFromCache(byUserHandle: peerId) else {
                        continuation.resume(throwing: ChatRoomErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: name)
                case .failure:
                    continuation.resume(throwing: ChatRoomErrorEntity.generic)
                }
            }
            
            chatSdk.loadUserAttributes(forChatId: chatRoom.chatId, usersHandles: [NSNumber(value: peerId)], delegate: delegate, queueType: .globalBackground)
        }
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        chatSdk.contactEmail(byHandle: userHandle)
    }
    
    public func userEmail(forUserHandle userHandle: HandleEntity) async throws -> String {
        if let contactEmail = chatSdk.contactEmail(byHandle: userHandle) {
            return contactEmail
        } else if let cachedUserEmail = chatSdk.userEmailFromCache(byUserHandle: userHandle) {
            return cachedUserEmail
        } else {
            return try await withAsyncThrowingValue { completion in
                chatSdk.userEmail(byUserHandle: userHandle, delegate: ChatRequestDelegate { result in
                    switch result {
                    case .success(let request):
                        if let text = request.text {
                            completion(.success(text))
                        } else {
                            completion(.failure(ChatRoomErrorEntity.emptyTextResponse))
                        }
                    case .failure:
                        completion(.failure(ChatRoomErrorEntity.generic))
                    }
                })
            }
        }
    }
}
