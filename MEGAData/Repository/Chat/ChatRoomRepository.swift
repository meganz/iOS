

struct ChatRoomRepository: ChatRoomRepositoryProtocol {
    private let sdk: MEGAChatSdk
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func chatRoom(forUserHandle userHandle: UInt64) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(byUser: userHandle) {
            return ChatRoomEntity(with: megaChatRoom)
        }
        
        return nil
    }
    
    func createChatRoom(forUserHandle userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, Error>) -> Void) {
        if let chatRoom = chatRoom(forUserHandle: userHandle) {
            completion(.success(chatRoom))
        }
        
        sdk.mnz_createChatRoom(userHandle: userHandle) { megaChatRoom in
            completion(.success(ChatRoomEntity(with: megaChatRoom)))
        }
    }
    
    func createPublicLink(forChatId chatId: UInt64, completion: @escaping (Result<String, ChatLinkError>) -> Void) {
        let publicChatLinkCreationDelegate = MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(request.text))
        }
        
        sdk.createChatLink(chatId, delegate: publicChatLinkCreationDelegate)
    }
    
    func queryChatLink(forChatId chatId: UInt64, completion: @escaping (Result<String, ChatLinkError>) -> Void) {
        let publicChatLinkCreationDelegate = ChatRequestListener { (request, error) in
            guard let error = error, error.type == .MEGAChatErrorTypeOk else {
                if let error = error, error.type == .MEGAChatErrorTypeNoEnt {
                    completion(.failure(.resourceNotFound))
                } else {
                    completion(.failure(.generic))
                }
                return
            }
            
            if let request = request {
                completion(.success(request.text))
            } else {
                completion(.failure(.noRequestObjectFound))
            }
        }
        
        sdk.queryChatLink(chatId, delegate: publicChatLinkCreationDelegate)
    }
    
    func userFullName(forPeerId peerId: UInt64, chatId: UInt64, completion: @escaping (Result<String, Error>) -> Void) {
        if let name = sdk.userFullnameFromCache(byUserHandle: peerId) {
            completion(.success(name))
            return
        }
        
        let delegate = MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type != .MEGAChatErrorTypeOk else {
                MEGALogDebug("error fetching user attributes \(error.type) : \(error.name ?? "")")
                return
            }
            
            if let name = sdk.userFullnameFromCache(byUserHandle: peerId) {
                completion(.success(name))
            }
        }
        
        sdk.loadUserAttributes(forChatId: chatId, usersHandles: [NSNumber(value: peerId)], delegate: delegate)
    }
    
    func renameChatRoom(chatId: MEGAHandle, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        sdk.setChatTitle(chatId, title: title, delegate: MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(request.text))
        })
    }
}

fileprivate final class ChatRequestListener: NSObject, MEGAChatRequestDelegate {
    typealias Completion = (_ request: MEGAChatRequest?, _ error: MEGAChatError?) -> Void
    private let completion: Completion
    
    init(completion: @escaping Completion) {
        self.completion = completion
        super.init()
    }
    
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        completion(request, error)
    }
}
