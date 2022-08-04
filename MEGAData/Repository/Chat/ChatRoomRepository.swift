import Combine

struct ChatRoomRepository: ChatRoomRepositoryProtocol {
    private let sdk: MEGAChatSdk
    private var participantsUpdateListener: ChatRoomUpdateListener?
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(forChatId: chatId) {
            return ChatRoomEntity(with: megaChatRoom)
        }
        
        return nil
    }
    
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(byUser: userHandle) {
            return ChatRoomEntity(with: megaChatRoom)
        }
        
        return nil
    }
    
    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity] {
        guard let chatRoom = chatRoom(forChatId: chatId) else { return [] }
        return chatRoom.peerHandles
    }
    
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomEntity.Privilege? {
        guard let chatRoom = sdk.chatRoom(forChatId: chatId), let privilege = ChatRoomEntity.Privilege(rawValue: chatRoom.peerPrivilege(byHandle: userHandle)) else {
            return nil
        }
        return privilege
    }
    
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        if let chatRoom = chatRoom(forUserHandle: userHandle) {
            completion(.success(chatRoom))
        }
        
        sdk.mnz_createChatRoom(userHandle: userHandle) { megaChatRoom in
            completion(.success(ChatRoomEntity(with: megaChatRoom)))
        }
    }
    
    func createPublicLink(forChatId chatId: HandleEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
        let publicChatLinkCreationDelegate = MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(request.text))
        }
        
        sdk.createChatLink(chatId, delegate: publicChatLinkCreationDelegate)
    }
    
    func queryChatLink(forChatId chatId: HandleEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
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
    
    func userFullName(forPeerId peerId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        if let name = sdk.userFullnameFromCache(byUserHandle: peerId) {
            MEGALogDebug("user name is \(name) for handle \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
            completion(.success(name))
            return
        }
        
        let delegate = MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk,
                  let name = sdk.userFullnameFromCache(byUserHandle: peerId) else {
                MEGALogDebug("error fetching name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name") attributes \(error.type) : \(error.name ?? "")")
                completion(.failure(.generic))
                return
            }
            
            completion(.success(name))
        }
        
        MEGALogDebug("Load user name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
        sdk.loadUserAttributes(forChatId: chatId, usersHandles: [NSNumber(value: peerId)], delegate: delegate)
    }
    
    func userFullName(forPeerId peerId: HandleEntity, chatId: HandleEntity) async throws -> String {
        if let name = sdk.userFullnameFromCache(byUserHandle: peerId) {
            MEGALogDebug("user name is \(name) for handle \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
            return name
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = MEGAChatGenericRequestDelegate { (request, error) in
                guard error.type == .MEGAChatErrorTypeOk,
                      let name = sdk.userFullnameFromCache(byUserHandle: peerId) else {
                    MEGALogDebug("error fetching name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name") attributes \(error.type) : \(error.name ?? "")")
                    continuation.resume(throwing: ChatRoomErrorEntity.generic)
                    return
                }
                
                continuation.resume(returning: name)
            }
            

            MEGALogDebug("Load user name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
            sdk.loadUserAttributes(forChatId: chatId, usersHandles: [NSNumber(value: peerId)], delegate: delegate)
        }
    }

    func renameChatRoom(chatId: HandleEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        MEGALogDebug("Renaming the chat for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "No name") with title \(title)")
        sdk.setChatTitle(chatId, title: title, delegate: MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk else {
                MEGALogDebug("Renaming the chat for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "No name") with title \(title) failed with error \(error)")
                completion(.failure(.generic))
                return
            }
            
            guard let text = request.text else {
                MEGALogDebug("Renaming the chat for \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "No name") with title \(title) with text nil")
                completion(.failure(.emptyTextResponse))
                return
            }
            
            completion(.success(text))
        })
    }
    
    mutating func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never> {
        let participantsUpdateListener = ChatRoomUpdateListener(sdk: sdk, chatId: chatId, changeType: .participants)
        self.participantsUpdateListener = participantsUpdateListener
        return participantsUpdateListener
            .monitor
            .map(\.peerHandles)
            .eraseToAnyPublisher()
    }
    
    mutating func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        let participantsUpdateListener = ChatRoomUpdateListener(sdk: sdk, chatId: chatId, changeType: .participants)
        self.participantsUpdateListener = participantsUpdateListener
        return participantsUpdateListener
            .monitor
            .map(\.userHandle)
            .eraseToAnyPublisher()
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

fileprivate final class ChatRoomUpdateListener: NSObject, MEGAChatRoomDelegate {
    private let sdk: MEGAChatSdk
    private let changeType: ChatRoomEntity.ChangeType
    private let chatId: HandleEntity
    
    private let source = PassthroughSubject<ChatRoomEntity, Never>()
    
    var monitor: AnyPublisher<ChatRoomEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, chatId: HandleEntity, changeType: ChatRoomEntity.ChangeType) {
        self.sdk = sdk
        self.changeType = changeType
        self.chatId = chatId
        super.init()
        sdk.addChatRoomDelegate(chatId, delegate: self)
    }
    
    deinit {
        sdk.removeChatRoomDelegate(chatId, delegate: self)
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        guard case let chatRoom = ChatRoomEntity(with: chat),
              chatRoom.changeType == changeType else {
            return
        }
        source.send(chatRoom)
    }
}
