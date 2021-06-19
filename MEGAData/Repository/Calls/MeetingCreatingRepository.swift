import Foundation

final class MeetingCreatingRepository: NSObject, MEGAChatDelegate, MeetingCreatingRepositoryProtocol {
    
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private let sdk = MEGASdkManager.sharedMEGASdk()
    private var chatResultDelegate: MEGAChatResultDelegate?
    func setChatVideoInDevices(device: String) {
        chatSdk.setChatVideoInDevices(device)
    }
    
    func openVideoDevice() {
        chatSdk.openVideoDevice()
    }
    
    func videoDevices() -> [String] {
        chatSdk.chatVideoInDevices()?.toArray() ?? []
    }
    
    func releaseDevice() {
        chatSdk.releaseVideoDevice()
    }
    
    func getUsername() -> String {
        let user = MEGAStore.shareInstance().fetchUser(withEmail: sdk.myEmail)
        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }
        
        return chatSdk.userFullnameFromCache(byUserHandle:  sdk.myUser?.handle ?? 0) ?? ""

    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        guard let call = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return CallEntity(with: call)
    }
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                return
            }
            self?.chatSdk.startChatCall(chatroom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: MEGAChatStartCallRequestDelegate(completion: { [weak self] (chatError) in
                if chatError?.type == .MEGAChatErrorTypeOk {
                    guard (self?.chatSdk.chatCall(forChatId: request.chatHandle)) != nil else {
                        completion(.failure(.generic))
                        return
                    }
                    completion(.success(ChatRoomEntity(with: chatroom)))
                } else {
                    completion(.failure(.generic))
                }
            }))

        }
        
        chatSdk.createMeeting(withTitle: meetingName, delegate: delegate)
    }

    func addChatLocalVideo(delegate: MEGAChatVideoDelegate) {
       chatSdk.addChatLocalVideo(123, delegate: delegate)
    }

    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                completion(.failure(.generic))
                return
            }

            MEGALogDebug("Create meeting: Answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            self?.chatSdk.answerChatCall(chatroom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: MEGAChatAnswerCallRequestDelegate { [weak self] (chatError) in
                if chatError?.type == .MEGAChatErrorTypeOk {
                    guard (self?.chatSdk.chatCall(forChatId: request.chatHandle)) != nil else {
                        MEGALogDebug("Create meeting: not able to find call with chat id \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                        completion(.failure(.generic))
                        return
                    }
                    
                    MEGALogDebug("Create meeting: success to answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                    completion(.success(ChatRoomEntity(with: chatroom)))
                } else {
                    MEGALogDebug("Create meeting: failed to answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                    completion(.failure(.generic))
                }
            })
        }
        
        chatSdk.autojoinPublicChat(chatId, delegate: delegate)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        guard let url = URL(string: link) else {
            completion(.failure(.generic))
            return
        }
        
        MEGALogDebug("Create meeting: check chat link \(link)")
        chatSdk.checkChatLink(url, delegate: MEGAChatGenericRequestDelegate(completion: { [weak self] (request, error) in
          
            guard (error.type == .MEGAChatErrorTypeOk || error.type == .MegaChatErrorTypeExist) else {
                MEGALogDebug("Create meeting: failed to check chat link \(link)")
                completion(.failure(.generic))
                return
            }
            
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("Create meeting: ChatRoom not found with chat handle \(request.chatHandle)")
                completion(.failure(.generic))
                return
            }
            
            MEGALogDebug("Create meeting: check chat link succeded with chatroom \(chatroom)")
            completion(.success(ChatRoomEntity(with: chatroom)))
        }))
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void) {
        MEGALogDebug("Create meeting: Now logging out of anonymous account")
        chatSdk.logout(with: MEGAChatResultRequestDelegate(completion: { (result) in
            switch result {
            case .success(_):
                self.chatSdk.initKarere(withSid: nil)
                MEGALogDebug("Create meeting: Now creating ephemeral account plus plus with firstname - \(firstName) and lastname - \(lastName)")
                self.sdk.createEphemeralAccountPlusPlus(withFirstname: firstName, lastname: lastName, delegate: MEGAResultRequestDelegate { (result) in
                    switch result {
                    case .failure(let errorType):
                        MEGALogDebug("Create meeting: failed creating ephemeral account plus plus with error \(errorType)")
                        completion(.failure(errorType))
                    case .success(let request):
                        MEGALogDebug("Create meeting: success creating ephemeral account plus plus")
                        if request.paramType == AccountActionType.resumeEphemeralPlusPlus.rawValue {
                            MEGALogDebug("Create meeting: Now fetching node for ephemeral account")
                            self.sdk.fetchNodes(with: RequestDelegate(completion: { (result) in
                                switch result {
                                case .success(_):
                                    MEGALogDebug("Create meeting: success fetching node for ephemeral account and now connecting to chat")
                                    self.connectToChat(link: link, request: request, completion: completion)
                                case .failure(let error):
                                    MEGALogDebug("Create meeting: failure fetching node for ephemeral account \(error)")
                                    completion(.failure(.unexpected))
                                }
                            }))
                        } else {
                            self.connectToChat(link: link, request: request, completion: completion)
                        }
                    }
                })
            case .failure(let error):
                MEGALogDebug("Create meeting: failed to logout of anonymous account \(error)")
                completion(.failure(.unexpected))
            }
            
        }))
    }
    
    private func connectToChat(link: String, request: MEGARequest, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void) {
        guard let url = URL(string: link) else {
            MEGALogDebug("Create meeting: invalid url \(link)")
            completion(.failure(.unexpected))
            return
        }
        
        MEGALogDebug("Create meeting: connect to chat with link \(link) and request \(request)")
        self.chatSdk.connect(with: MEGAChatResultRequestDelegate(completion: { _  in
            MEGALogDebug("Create meeting: open chat preview for url \(url)")
            self.chatSdk.openChatPreview(url, delegate: MEGAChatResultRequestDelegate(completion: { [weak self] in
                switch $0 {
                case .success(let chatRequest):
                    MEGALogDebug("Create meeting: open chat preview succeeded with request \(chatRequest)")
                    self?.chatResultDelegate = MEGAChatResultDelegate(completion: { (sdk, chatId, newState) in
                        if chatRequest.chatHandle == chatId, newState == .online {
                            self?.chatSdk.remove(self?.chatResultDelegate)
                            completion(.success(()))
                        }
                    })
                    self?.chatSdk.add(self?.chatResultDelegate)
                case .failure(let error):
                    MEGALogDebug("Create meeting: open chat preview failure \(error)")
                    completion(.failure(.unexpected))
                }
            }))
        }))
    }
}

