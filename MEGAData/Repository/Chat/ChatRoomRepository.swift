import Combine
import MEGADomain

final class ChatRoomRepository: ChatRoomRepositoryProtocol {
    
    static var sharedRepo = ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
    
    private let sdk: MEGAChatSdk
    private var chatRoomUpdateListeners = [ChatRoomUpdateListener]()
    private var openChatRooms = Set<HandleEntity>()
    
    private init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(forChatId: chatId) {
            return megaChatRoom.toChatRoomEntity()
        }
        
        return nil
    }
    
    func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(byUser: userHandle) {
            return megaChatRoom.toChatRoomEntity()
        }
        
        return nil
    }
    
    func peerHandles(forChatId chatId: HandleEntity) -> [HandleEntity] {
        guard let chatRoom = chatRoom(forChatId: chatId) else { return [] }
        return chatRoom.peers.map(\.handle)
    }
    
    func peerPrivilege(forUserHandle userHandle: HandleEntity, inChatId chatId: HandleEntity) -> ChatRoomPrivilegeEntity? {
        guard let chatRoom = sdk.chatRoom(forChatId: chatId), let privilege = MEGAChatRoomPrivilege(rawValue: chatRoom.peerPrivilege(byHandle: userHandle))?.toOwnPrivilegeEntity() else {
            return nil
        }
        return privilege
    }
    
    func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        sdk.userOnlineStatus(userHandle).toChatStatusEntity()
    }
    
    func createChatRoom(forUserHandle userHandle: HandleEntity, completion: @escaping (Result<ChatRoomEntity, ChatRoomErrorEntity>) -> Void) {
        if let chatRoom = chatRoom(forUserHandle: userHandle) {
            completion(.success(chatRoom))
        }
        
        sdk.mnz_createChatRoom(userHandle: userHandle) { megaChatRoom in
            completion(.success(megaChatRoom.toChatRoomEntity()))
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
        
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let self = self else { return }
            guard error.type == .MEGAChatErrorTypeOk,
                  let name = self.sdk.userFullnameFromCache(byUserHandle: peerId) else {
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
            let delegate = MEGAChatGenericRequestDelegate { [weak self]  (request, error) in
                guard let self = self else { return }
                guard error.type == .MEGAChatErrorTypeOk,
                      let name = self.sdk.userFullnameFromCache(byUserHandle: peerId) else {
                    MEGALogDebug("error fetching name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name") attributes \(error.type) : \(error.name ?? "")")
                    continuation.resume(throwing: ChatRoomErrorEntity.generic)
                    return
                }
                
                continuation.resume(returning: name)
            }
            

            MEGALogDebug("Load user name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
            sdk.loadUserAttributes(forChatId: chatId, usersHandles: [NSNumber(value: peerId)], delegate: delegate, queueType: .globalBackground)
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
    
    func message(forChatId chatId: ChatIdEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        sdk.message(forChat: chatId, messageId: messageId)?.toChatMessageEntity()
    }
    
    func archive(_ archive: Bool, chatId: ChatIdEntity) {
        sdk.archiveChat(chatId, archive: archive)
    }
    
    func setMessageSeenForChat(forChatId chatId: ChatIdEntity,  messageId: HandleEntity) {
        sdk.setMessageSeenForChat(chatId, messageId: messageId)
    }
    
    func base64Handle(forChatId chatId: ChatIdEntity) -> String? {
        MEGASdk.base64Handle(forUserHandle: chatId)
    }
    
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        sdk.contactEmail(byHandle: userHandle)
    }
    
    func allowNonHostToAddParticipants(enabled: Bool, chatId: HandleEntity) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let requestDelegate = ChatRequestListener { (request, error) in
                guard let error = error, error.type == .MEGAChatErrorTypeOk else {
                    if let error = error {
                        if error.type == .MEGAChatErrorTypeNoEnt {
                            continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.chatRoomDoesNoExists)
                        } else if error.type == .MEGAChatErrorTypeArgs {
                            continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.oneToOneChatRoom)
                        } else if error.type == .MEGAChatErrorTypeAccess {
                            continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.access)
                        } else if error.type == .MegaChatErrorTypeExist {
                            continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.alreadyExists)
                        } else {
                            continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.generic)
                        }
                    } else {
                        continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.generic)
                    }
                    return
                }
                
                if let enabled = request?.isFlag {
                    continuation.resume(returning: enabled)
                } else {
                    continuation.resume(throwing: AllowNonHostToAddParticipantsErrorEntity.generic)
                }
            }
            
            sdk.openInvite(enabled, chatId: chatId, delegate: requestDelegate)
        }
    }
    
    func participantsUpdated(forChatId chatId: HandleEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomUpdateListener(forChatId: chatId)
            .monitor
            .filter{ $0.changeType == .participants }
            .map({ $0.peers.map({ $0.handle })})
            .eraseToAnyPublisher()
    }
    
    func userPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomUpdateListener(forChatId: chatId)
            .monitor
            .filter{ $0.changeType == .participants }
            .map(\.userHandle)
            .eraseToAnyPublisher()
    }
    
    func ownPrivilegeChanged(forChatId chatId: HandleEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomUpdateListener(forChatId: chatId)
            .monitor
            .filter{ $0.changeType == .ownPrivilege }
            .map(\.userHandle)
            .eraseToAnyPublisher()
    }
    
    func allowNonHostToAddParticipantsValueChanged(forChatId chatId: HandleEntity) -> AnyPublisher<Bool, Never> {
        chatRoomUpdateListener(forChatId: chatId)
            .monitor
            .filter{ $0.changeType == .openInvite}
            .map(\.isOpenInviteEnabled)
            .eraseToAnyPublisher()
    }
    
    private func chatRoomUpdateListener(forChatId chatId: HandleEntity) -> ChatRoomUpdateListener {
        guard let chatRoomUpdateListener = chatRoomUpdateListeners.filter({ $0.chatId == chatId }).first else {
            let chatRoomUpdateListener = ChatRoomUpdateListener(sdk: sdk, chatId: chatId)
            chatRoomUpdateListeners.append(chatRoomUpdateListener)
            return chatRoomUpdateListener
        }
        
        return chatRoomUpdateListener
    }
    
    func isChatRoomOpen(chatId: HandleEntity) -> Bool {
        openChatRooms.contains(chatId)
    }
    
    func openChatRoom(chatId: HandleEntity, callback: @escaping (ChatRoomCallbackEntity) -> Void) throws {
        try openChatRoom(chatId: chatId, delegate: ChatRoomRepoDelegate(callback: callback))
    }
    
    func closeChatRoom(chatId: HandleEntity, callback: @escaping (ChatRoomCallbackEntity) -> Void) {
        closeChatRoom(chatId: chatId, delegate: ChatRoomRepoDelegate(callback: callback))
    }
    
    func openChatRoom(chatId: HandleEntity, delegate: MEGAChatRoomDelegate) throws {
        openChatRooms.insert(chatId)
        if !sdk.openChatRoom(chatId, delegate: delegate) {
            throw ChatRoomErrorEntity.generic
        }
    }
    
    func closeChatRoom(chatId: HandleEntity, delegate: MEGAChatRoomDelegate) {
        openChatRooms.remove(chatId)
        let listenersForChatId = chatRoomUpdateListeners.filter { $0.chatId == chatId }
        listenersForChatId.forEach({ listener in
            chatRoomUpdateListeners.remove(object: listener)
        })
        return sdk.closeChatRoom(chatId, delegate: delegate)
    }
    
    func closeChatRoomPreview(chatRoom: ChatRoomEntity) {
        sdk.closeChatPreview(chatRoom.chatId)
    }
    
    func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool {
        await withCheckedContinuation { continuation in
            sdk.leaveChat(chatRoom.chatId, delegate: ChatRequestListener { (request, error) in
                guard let error, error.type == .MEGAChatErrorTypeOk else {
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(returning: true)
            })
        }
    }
    
    func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) {
        sdk.updateChatPermissions(chatRoom.chatId, userHandle: userHandle, privilege: privilege.toMEGAChatRoomPrivilege().rawValue)
    }
    
    func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        sdk.invite(toChat: chat.chatId, user: userId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) {
        sdk.remove(fromChat: chat.chatId, userHandle: userId)
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
    let chatId: HandleEntity
    
    private let source = PassthroughSubject<ChatRoomEntity, Never>()
    
    var monitor: AnyPublisher<ChatRoomEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, chatId: HandleEntity) {
        self.sdk = sdk
        self.chatId = chatId
        super.init()
        sdk.addChatRoomDelegate(chatId, delegate: self)
    }
    
    deinit {
        sdk.removeChatRoomDelegate(chatId, delegate: self)
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        source.send(chat.toChatRoomEntity())
    }
}

fileprivate class ChatRoomRepoDelegate: NSObject, MEGAChatRoomDelegate {
    private let callback: (ChatRoomCallbackEntity) -> Void
    
    init(callback: @escaping (ChatRoomCallbackEntity) -> Void) {
        self.callback = callback
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        callback(.onUpdate(chat.toChatRoomEntity()))
    }
}
