import Foundation
import MEGAChatSdk
import MEGADomain
import MEGASDKRepo
import MEGASwift

public final class MeetingCreatingRepository: NSObject, MEGAChatDelegate, MeetingCreatingRepositoryProtocol, Sendable {
    
    public static var newRepo: MeetingCreatingRepository {
        MeetingCreatingRepository(
            chatSdk: .sharedChatSdk,
            sdk: .sharedSdk,
            chatConnectionStateUpdateProvider: ChatConnectionStateUpdateProvider(sdk: .sharedChatSdk)
        )
    }
    
    private let chatSdk: MEGAChatSdk
    private let sdk: MEGASdk
    private let chatConnectionStateUpdateProvider: any ChatConnectionStateUpdateProviderProtocol
    
    init(
        chatSdk: MEGAChatSdk,
        sdk: MEGASdk,
        chatConnectionStateUpdateProvider: some ChatConnectionStateUpdateProviderProtocol
    ) {
        self.chatSdk = chatSdk
        self.sdk = sdk
        self.chatConnectionStateUpdateProvider = chatConnectionStateUpdateProvider
    }
    
    public func username() -> String {
        chatSdk.userFullnameFromCache(byUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? 0) ?? ""
    }
    
    public func userEmail() -> String? {
        sdk.myEmail
    }
    
    public func createChatLink(forChatId chatId: UInt64) {
        chatSdk.createChatLink(chatId)
    }
    
    public func createMeeting(_ startCall: StartCallEntity) async throws -> ChatRoomEntity {
        try await withAsyncThrowingValue { result in
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
            chatSdk.createMeeting(
                withTitle: startCall.meetingName,
                speakRequest: startCall.speakRequest,
                waitingRoom: startCall.waitingRoom,
                openInvite: startCall.allowNonHostToAddParticipants,
                queueType: .main,
                delegate: delegate
            )
        }
    }
    
    public func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        let delegate = ChatRequestDelegate { [weak self] result in
            switch result {
            case .success(let request):
                guard let self, let megaChatRoom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                    completion(.failure(.generic))
                    return
                }
                
                let chatRoom = megaChatRoom.toChatRoomEntity()
                completion(.success(chatRoom))
            case .failure:
                completion(.failure(.generic))
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
    
    public func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        guard let url = URL(string: link) else {
            completion(.failure(.generic))
            return
        }
        
        chatSdk.checkChatLink(url, delegate: ChatRequestDelegate { [weak self] result in
            guard let self else {
                completion(.failure(.generic))
                return
            }
            switch result {
            case .success(let request):
                guard let chatroom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                    completion(.failure(.generic))
                    return
                }
                
                completion(.success(chatroom.toChatRoomEntity()))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
    
    public func createEphemeralAccountAndJoinChat(
        firstName: String,
        lastName: String,
        link: String,
        completion: @escaping @Sendable (Result<Void, GenericErrorEntity>) -> Void,
        karereInitCompletion: @escaping () -> Void
    ) {
        chatSdk.logout(with: ChatRequestDelegate { [weak self] result in
            guard let self else {
                completion(.failure(GenericErrorEntity()))
                return
            }
            switch result {
            case .success:
                chatSdk.initKarere(withSid: nil)
                karereInitCompletion()
                sdk.createEphemeralAccountPlusPlus(withFirstname: firstName, lastname: lastName, delegate: RequestDelegate { [weak self] result in
                    guard let self else {
                        completion(.failure(GenericErrorEntity()))
                        return
                    }
                    switch result {
                    case .failure:
                        completion(.failure(GenericErrorEntity()))
                    case .success(let request):
                        if request.paramType == AccountActionType.resumeEphemeralPlusPlus.rawValue {
                            sdk.fetchNodes(with: RequestDelegate { [weak self] result in
                                switch result {
                                case .success:
                                    self?.connectToChat(link: link, completion: completion)
                                case .failure:
                                    completion(.failure(GenericErrorEntity()))
                                }
                            })
                        } else {
                            connectToChat(link: link, completion: completion)
                        }
                    }
                })
            case .failure:
                completion(.failure(GenericErrorEntity()))
            }
        })
    }
    
    private func connectToChat(link: String, completion: @escaping @Sendable (Result<Void, GenericErrorEntity>) -> Void) {
        guard let url = URL(string: link) else {
            completion(.failure(GenericErrorEntity()))
            return
        }
        
        chatSdk.openChatPreview(url, delegate: ChatRequestDelegate { [weak self] result in
            guard let self else {
                completion(.failure(GenericErrorEntity()))
                return
            }
            switch result {
            case .success(let chatRequest):
                Task { [weak self] in
                    guard let self else { return }
                    await handleChatConnection(
                        chatRequest: chatRequest,
                        completion: completion
                    )
                }
            case .failure:
                completion(.failure(GenericErrorEntity()))
            }
        })
    }
    
    private func handleChatConnection(
        chatRequest: MEGAChatRequest,
        completion: @escaping @Sendable (Result<Void, GenericErrorEntity>) -> Void
    ) async {
        let chatHandle = chatRequest.chatHandle
        _ = await chatConnectionStateUpdateProvider
            .updates
            .first { $0 == chatHandle && $1 == .online }
        guard !Task.isCancelled else {
            completion(.failure(GenericErrorEntity()))
            return
        }
        completion(.success)
    }
}
