import ChatRepo
import Foundation
import MEGADomain
import MEGASDKRepo
import MEGASwift

final class MeetingCreatingRepository: NSObject, MEGAChatDelegate, MeetingCreatingRepositoryProtocol {
    
    static var newRepo: MeetingCreatingRepository {
        MeetingCreatingRepository(chatSdk: .sharedChatSdk, sdk: .sharedSdk)
    }
    
    private let chatSdk: MEGAChatSdk
    private let sdk: MEGASdk
    private var chatResultDelegate: MEGAChatResultDelegate?
    
    init(chatSdk: MEGAChatSdk, sdk: MEGASdk) {
        self.chatSdk = chatSdk
        self.sdk = sdk
    }
    
    func getUsername() -> String {
        if let email = sdk.myEmail,
            let user = MEGAStore.shareInstance().fetchUser(withEmail: email),
            case let userName = user.displayName,
            userName.isNotEmpty {
            return userName
        }
        
        return chatSdk.userFullnameFromCache(byUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? 0) ?? ""
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        guard let call = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return call.toCallEntity()
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        chatSdk.createChatLink(chatId)
    }
    
    func createMeeting(_ startCall: StartCallEntity) async throws -> ChatRoomEntity {
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

    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        let delegate = ChatRequestDelegate { [weak self] result in
            switch result {
            case .success(let request):
                guard let self, let megaChatRoom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                    MEGALogDebug("ChatRoom not found with chat handle \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
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
            MEGALogDebug("Create meeting: Autojoin public chat with chatId - \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            chatSdk.autojoinPublicChat(chatId, delegate: delegate)
        }
    }

    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        guard let url = URL(string: link) else {
            completion(.failure(.generic))
            return
        }
        
        MEGALogDebug("Create meeting: check chat link \(link)")
        chatSdk.checkChatLink(url, delegate: ChatRequestDelegate { [weak self] result in
            guard let self else {
                completion(.failure(.generic))
                return
            }
            switch result {
            case .success(let request):
                
                guard let chatroom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                    MEGALogDebug("Create meeting: ChatRoom not found with chat handle \(request.chatHandle)")
                    completion(.failure(.generic))
                    return
                }
                
                MEGALogDebug("Create meeting: check chat link succeeded with chatroom \(chatroom)")
                completion(.success(chatroom.toChatRoomEntity()))
            case .failure(let error):
                if error.type == .MegaChatErrorTypeExist {
                    MEGALogDebug("Create meeting: failed to check chat link \(link)")
                }
                completion(.failure(.generic))
            }
        })
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void) {
        MEGALogDebug("Create meeting: Now logging out of anonymous account")
        chatSdk.logout(with: ChatRequestDelegate { [weak self] result in
            guard let self else {
                completion(.failure(.unexpected))
                return
            }
            switch result {
            case .success:
                chatSdk.initKarere(withSid: nil)
                karereInitCompletion()
                MEGALogDebug("Create meeting: Now creating ephemeral account plus plus with firstname - \(firstName) and lastname - \(lastName)")
                sdk.createEphemeralAccountPlusPlus(withFirstname: firstName, lastname: lastName, delegate: RequestDelegate { [weak self] result in
                    guard let self else {
                        completion(.failure(.unexpected))
                        return
                    }
                    switch result {
                    case .failure(let errorType):
                        MEGALogDebug("Create meeting: failed creating ephemeral account plus plus with error \(errorType)")
                        completion(.failure(.unexpected))
                    case .success(let request):
                        MEGALogDebug("Create meeting: success creating ephemeral account plus plus")
                        if request.paramType == AccountActionType.resumeEphemeralPlusPlus.rawValue {
                            MEGALogDebug("Create meeting: Now fetching node for ephemeral account")
                            sdk.fetchNodes(with: RequestDelegate { [weak self] result in
                                switch result {
                                case .success:
                                    MEGALogDebug("Create meeting: success fetching node for ephemeral account and now connecting to chat")
                                    self?.connectToChat(link: link, completion: completion)
                                case .failure(let error):
                                    MEGALogDebug("Create meeting: failure fetching node for ephemeral account \(error)")
                                    completion(.failure(.unexpected))
                                }
                            })
                        } else {
                            connectToChat(link: link, completion: completion)
                        }
                    }
                })
            case .failure(let error):
                MEGALogDebug("Create meeting: failed to logout of anonymous account \(error)")
                completion(.failure(.unexpected))
            }
        })
    }
    
    private func connectToChat(link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void) {
        guard let url = URL(string: link) else {
            MEGALogDebug("Create meeting: invalid url \(link)")
            completion(.failure(.unexpected))
            return
        }
        
        MEGALogDebug("Create meeting: open chat preview for url \(url)")
        chatSdk.openChatPreview(url, delegate: ChatRequestDelegate { [weak self]  result in
            guard let self else {
                completion(.failure(.unexpected))
                return
            }
            switch result {
            case .success(let chatRequest):
                MEGALogDebug("Create meeting: open chat preview succeeded with request \(chatRequest)")
                chatResultDelegate = MEGAChatResultDelegate { [weak self] _, chatId, newState in
                    guard let self else {
                        completion(.failure(.unexpected))
                        return
                    }
                    if chatRequest.chatHandle == chatId, newState == .online, let chatResultDelegate {
                        chatSdk.remove(chatResultDelegate)
                        completion(.success(()))
                    }
                }
                if let chatResultDelegate {
                    chatSdk.add(chatResultDelegate)
                }
            case .failure(let error):
                MEGALogDebug("Create meeting: open chat preview failure \(error)")
                completion(.failure(.unexpected))
            }
        })
    }
}
