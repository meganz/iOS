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
    
    func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity] {
        chatRoom.peers.map(\.handle)
    }
    
    func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity? {
        guard let megaChatRoom = sdk.chatRoom(forChatId: chatRoom.chatId),
                let privilege = MEGAChatRoomPrivilege(rawValue: megaChatRoom.peerPrivilege(byHandle: userHandle))?.toOwnPrivilegeEntity() else {
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

    func createPublicLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
        let publicChatLinkCreationDelegate = MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(request.text))
        }
        
        sdk.createChatLink(chatRoom.chatId, delegate: publicChatLinkCreationDelegate)
    }
    
    func queryChatLink(forChatRoom chatRoom: ChatRoomEntity, completion: @escaping (Result<String, ChatLinkErrorEntity>) -> Void) {
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
        
        sdk.queryChatLink(chatRoom.chatId, delegate: publicChatLinkCreationDelegate)
    }

    func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String, completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        MEGALogDebug("Renaming the chat for \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "No name") with title \(title)")
        sdk.setChatTitle(chatRoom.chatId, title: title, delegate: MEGAChatGenericRequestDelegate { (request, error) in
            guard error.type == .MEGAChatErrorTypeOk else {
                MEGALogDebug("Renaming the chat for \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "No name") with title \(title) failed with error \(error)")
                completion(.failure(.generic))
                return
            }
            
            guard let text = request.text else {
                MEGALogDebug("Renaming the chat for \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "No name") with title \(title) with text nil")
                completion(.failure(.emptyTextResponse))
                return
            }
            
            completion(.success(text))
        })
    }
    
    func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        sdk.message(forChat: chatRoom.chatId, messageId: messageId)?.toChatMessageEntity()
    }
    
    func archive(_ archive: Bool, chatRoom: ChatRoomEntity) {
        sdk.archiveChat(chatRoom.chatId, archive: archive)
    }
    
    func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity,  messageId: HandleEntity) {
        sdk.setMessageSeenForChat(chatRoom.chatId, messageId: messageId)
    }
    
    func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String? {
        MEGASdk.base64Handle(forUserHandle: chatRoom.chatId)
    }
    
    func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
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
            
            sdk.openInvite(enabled, chatId: chatRoom.chatId, delegate: requestDelegate)
        }
    }
    
    func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter{ $0.changeType == .participants }
            .map({ $0.peers.map({ $0.handle })})
            .eraseToAnyPublisher()
    }
    
    func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter{ $0.changeType == .participants }
            .map(\.userHandle)
            .eraseToAnyPublisher()
    }
    
    func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter{ $0.changeType == .ownPrivilege }
            .map(\.userHandle)
            .eraseToAnyPublisher()
    }
    
    func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
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
    
    func isChatRoomOpen(_ chatRoom: ChatRoomEntity) -> Bool {
        openChatRooms.contains(chatRoom.chatId)
    }
    
    func openChatRoom(_ chatRoom: ChatRoomEntity, delegate: ChatRoomDelegateEntity) throws {
        try openChatRoom(chatId: chatRoom.chatId, delegate: ChatRoomDelegateDTO(chatId: chatRoom.chatId, chatRoomDelegate: delegate))
    }
    
    func closeChatRoom(_ chatRoom: ChatRoomEntity, delegate: ChatRoomDelegateEntity) {
        closeChatRoom(chatId: chatRoom.chatId, delegate: ChatRoomDelegateDTO(chatId: chatRoom.chatId, chatRoomDelegate: delegate))
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
        sdk.closeChatRoom(chatId, delegate: delegate)
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

fileprivate class ChatRoomDelegateDTO: NSObject, MEGAChatRoomDelegate {
    private let chatId: ChatIdEntity
    private let chatRoomDelegate: ChatRoomDelegateEntity

    init(chatId: ChatIdEntity, chatRoomDelegate: ChatRoomDelegateEntity) {
        self.chatId = chatId
        self.chatRoomDelegate = chatRoomDelegate
        super.init()
        MEGAChatSdk.shared.addChatRoomDelegate(chatId, delegate: self)
    }
    
    deinit {
        MEGAChatSdk.shared.removeChatRoomDelegate(chatId, delegate: self)
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        chatRoomDelegate.onChatRoomUpdate?(chat.toChatRoomEntity())
    }
    
    func onMessageLoaded(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        chatRoomDelegate.onMessageLoaded?(message.toChatMessageEntity())
    }
    
    func onMessageReceived(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        chatRoomDelegate.onMessageReceived?(message.toChatMessageEntity())
    }
    
    func onMessageUpdate(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        chatRoomDelegate.onMessageUpdate?(message.toChatMessageEntity())
    }
    
    func onHistoryReloaded(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        chatRoomDelegate.onHistoryReloaded?(chat.toChatRoomEntity())
    }
    
    func onReactionUpdate(_ api: MEGAChatSdk!, messageId: UInt64, reaction: String!, count: Int) {
        chatRoomDelegate.onReactionUpdate?(messageId, reaction, count)
    }
}
