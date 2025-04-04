import Combine
import MEGAAppSDKRepo
import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class ChatRoomRepository: ChatRoomRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: ChatRoomRepository {
        ChatRoomRepository(sdk: .sharedChatSdk,
                           chatUpdatesProvider: ChatUpdatesProvider(sdk: .sharedChatSdk)
        )
    }
    
    private let sdk: MEGAChatSdk
    @Atomic private var chatRoomUpdateListeners = [ChatRoomUpdateListener]()
    @Atomic private var chatRoomMessageLoadedListeners = [ChatRoomMessageLoadedListener]()
    @Atomic private var openChatRooms = Set<HandleEntity>()
    
    private let chatUpdatesProvider: any ChatUpdatesProviderProtocol

    public init(
        sdk: MEGAChatSdk,
        chatUpdatesProvider: some ChatUpdatesProviderProtocol
    ) {
        self.sdk = sdk
        self.chatUpdatesProvider = chatUpdatesProvider
    }
    
    public func chatRoom(forChatId chatId: HandleEntity) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(forChatId: chatId) {
            return megaChatRoom.toChatRoomEntity()
        }
        
        return nil
    }
    
    public func chatRoom(forUserHandle userHandle: HandleEntity) -> ChatRoomEntity? {
        if let megaChatRoom = sdk.chatRoom(byUser: userHandle) {
            return megaChatRoom.toChatRoomEntity()
        }
        
        return nil
    }
    
    public func peerHandles(forChatRoom chatRoom: ChatRoomEntity) -> [HandleEntity] {
        chatRoom.peers.map(\.handle)
    }
    
    public func peerPrivilege(forUserHandle userHandle: HandleEntity, chatRoom: ChatRoomEntity) -> ChatRoomPrivilegeEntity {
        guard let megaChatRoom = sdk.chatRoom(forChatId: chatRoom.chatId) else {
            return .unknown
        }
        return megaChatRoom.peerPrivilege(byHandle: userHandle).toChatRoomPrivilegeEntity()
    }
    
    public func userStatus(forUserHandle userHandle: HandleEntity) -> ChatStatusEntity {
        sdk.userOnlineStatus(userHandle).toChatStatusEntity()
    }
    
    public func createChatRoom(forUserHandle userHandle: HandleEntity) async throws -> ChatRoomEntity {
        if let chatRoom = chatRoom(forUserHandle: userHandle) {
            return chatRoom
        }
        
        return try await withAsyncThrowingValue { completion in
            sdk.createChatRoom(userHandle: userHandle) { result in
                switch result {
                case .success(let chatRoom):
                    completion(.success(chatRoom.toChatRoomEntity()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func createPublicLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String {
        try await withAsyncThrowingValue {  completion in
            sdk.createChatLink(chatRoom.chatId, delegate: ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    if let text = request.text {
                        completion(.success(text))
                    } else {
                        completion(.failure(ChatLinkErrorEntity.resourceNotFound))
                    }
                case .failure(let error):
                    completion(.failure(error.toChatLinkErrorEntity()))
                }
            })
        }
    }

    public func queryChatLink(forChatRoom chatRoom: ChatRoomEntity) async throws -> String {
        try await withAsyncThrowingValue {  completion in
            sdk.queryChatLink(chatRoom.chatId, delegate: ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    if let text = request.text {
                        completion(.success(text))
                    } else {
                        completion(.failure(ChatLinkErrorEntity.resourceNotFound))
                    }
                case .failure(let error):
                    completion(.failure(error.toChatLinkErrorEntity()))
                }
            })
        }
    }
    
    public func renameChatRoom(_ chatRoom: ChatRoomEntity, title: String) async throws -> String {
        try await withAsyncThrowingValue { completion in
            sdk.setChatTitle(
                chatRoom.chatId,
                title: title,
                delegate: ChatRequestDelegate { result in
                    switch result {
                    case .success(let request):
                        guard let updatedTitle = request.text else {
                            completion(.failure(ChatRoomErrorEntity.emptyTextResponse))
                            return
                        }
                        completion(.success(updatedTitle))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        }
    }
    
    public func message(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) -> ChatMessageEntity? {
        sdk.message(forChat: chatRoom.chatId, messageId: messageId)?.toChatMessageEntity()
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) {
        sdk.archiveChat(chatRoom.chatId, archive: archive)
    }
    
    public func archive(_ archive: Bool, chatRoom: ChatRoomEntity) async throws -> Bool {
        try await withAsyncThrowingValue {  completion in
            sdk.archiveChat(chatRoom.chatId, archive: archive, delegate: ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.isFlag))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func setMessageSeenForChat(forChatRoom chatRoom: ChatRoomEntity, messageId: HandleEntity) {
        sdk.setMessageSeenForChat(chatRoom.chatId, messageId: messageId)
    }
    
    public func base64Handle(forChatRoom chatRoom: ChatRoomEntity) -> String? {
        MEGASdk.base64Handle(forUserHandle: chatRoom.chatId)
    }
    
    public func allowNonHostToAddParticipants(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            let requestDelegate = ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.isFlag))
                case .failure(let error):
                    completion(.failure(error.toAllowNonHostToAddParticipantsErrorEntity()))
                }
            }
            sdk.openInvite(enabled, chatId: chatRoom.chatId, delegate: requestDelegate)
        }
    }
    
    public func waitingRoom(_ enabled: Bool, forChatRoom chatRoom: ChatRoomEntity) async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            sdk.setWaitingRoom(enabled, chatId: chatRoom.chatId, delegate: ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.isFlag))
                case .failure(let error):
                    completion(.failure(error.toWaitingRoomErrorEntity()))
                }
            })
        }
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<[HandleEntity], Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter { $0.changeType == .participants }
            .map({ $0.peers.map({ $0.handle })})
            .eraseToAnyPublisher()
    }
    
    public func participantsUpdated(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatRoomEntity, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter { $0.changeType == .participants }
            .eraseToAnyPublisher()
    }
    
    public func userPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter { $0.changeType == .participants }
            .map(\.userHandle)
            .eraseToAnyPublisher()
    }
    
    public func ownPrivilegeChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<HandleEntity, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter { $0.changeType == .ownPrivilege }
            .map(\.userHandle)
            .eraseToAnyPublisher()
    }
    
    public func allowNonHostToAddParticipantsValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter { $0.changeType == .openInvite}
            .map(\.isOpenInviteEnabled)
            .eraseToAnyPublisher()
    }
    
    public func waitingRoomValueChanged(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        chatRoomUpdateListener(forChatId: chatRoom.chatId)
            .monitor
            .filter { $0.changeType == .waitingRoom}
            .map(\.isWaitingRoomEnabled)
            .eraseToAnyPublisher()
    }
    
    private func chatRoomUpdateListener(forChatId chatId: HandleEntity) -> ChatRoomUpdateListener {
        guard let chatRoomUpdateListener = chatRoomUpdateListeners.filter({ $0.chatId == chatId }).first else {
            let chatRoomUpdateListener = ChatRoomUpdateListener(sdk: sdk, chatId: chatId)
            $chatRoomUpdateListeners.mutate { $0.append(chatRoomUpdateListener) }
            return chatRoomUpdateListener
        }
        
        return chatRoomUpdateListener
    }
    
    public func chatRoomMessageLoaded(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<ChatMessageEntity?, Never> {
        chatRoomMessageLoadedListener(forChatId: chatRoom.chatId)
            .monitor
            .eraseToAnyPublisher()
    }
    
    private func chatRoomMessageLoadedListener(forChatId chatId: HandleEntity) -> ChatRoomMessageLoadedListener {
        guard let chatRoomMessageLoadedListener = chatRoomMessageLoadedListeners.filter({ $0.chatId == chatId }).first else {
            let chatRoomMessageLoadedListener = ChatRoomMessageLoadedListener(sdk: sdk, chatId: chatId)
            $chatRoomMessageLoadedListeners.mutate { $0.append(chatRoomMessageLoadedListener) }
            return chatRoomMessageLoadedListener
        }
        
        return chatRoomMessageLoadedListener
    }
    
    public func isChatRoomOpen(_ chatRoom: ChatRoomEntity) -> Bool {
        openChatRooms.contains(chatRoom.chatId)
    }
    
    public func openChatRoom(_ chatRoom: ChatRoomEntity, delegate: ChatRoomDelegateEntity) throws {
        try openChatRoom(chatId: chatRoom.chatId, delegate: ChatRoomDelegateDTO(chatId: chatRoom.chatId, chatRoomDelegate: delegate))
    }
    
    public func closeChatRoom(_ chatRoom: ChatRoomEntity, delegate: ChatRoomDelegateEntity) {
        closeChatRoom(chatId: chatRoom.chatId, delegate: ChatRoomDelegateDTO(chatId: chatRoom.chatId, chatRoomDelegate: delegate))
    }
    
    public func openChatRoom(chatId: HandleEntity, delegate: some MEGAChatRoomDelegate) throws {
        $openChatRooms.mutate { $0.insert(chatId) }
        
        if !sdk.openChatRoom(chatId, delegate: delegate) {
            throw ChatRoomErrorEntity.generic
        }
    }
    
    public func closeChatRoom(chatId: HandleEntity, delegate: some MEGAChatRoomDelegate) {
        $openChatRooms.mutate { $0.remove(chatId) }
        $chatRoomUpdateListeners.mutate { $0.removeAll { $0.chatId == chatId } }
        $chatRoomMessageLoadedListeners.mutate { $0.removeAll { $0.chatId == chatId } }
        
        sdk.closeChatRoom(chatId, delegate: delegate)
    }
    
    public func closeChatRoomPreview(chatRoom: ChatRoomEntity) {
        sdk.closeChatPreview(chatRoom.chatId)
    }
    
    public func leaveChatRoom(chatRoom: ChatRoomEntity) async -> Bool {
        await withAsyncValue { completion in
            sdk.leaveChat(chatRoom.chatId, delegate: ChatRequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(true))
                case .failure:
                    completion(.success(false))
                }
            })
        }
    }
    
    public func updateChatPrivilege(chatRoom: ChatRoomEntity, userHandle: HandleEntity, privilege: ChatRoomPrivilegeEntity) async throws -> ChatRoomPrivilegeEntity {
        try await withAsyncThrowingValue { completion in
            let delegate = ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    let peerPrivilege = MEGAChatRoomPrivilege(rawValue: request.privilege)?.toChatRoomPrivilegeEntity() ?? .unknown
                    completion(.success(peerPrivilege))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            sdk.updateChatPermissions(
                chatRoom.chatId,
                userHandle: userHandle,
                privilege: privilege.toMEGAChatRoomPrivilege().rawValue,
                delegate: delegate
            )
        }
    }
    
    public func invite(toChat chat: ChatRoomEntity, userId: HandleEntity) {
        sdk.invite(toChat: chat.chatId, user: userId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    public func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) {
        sdk.remove(fromChat: chat.chatId, userHandle: userId)
    }
    
    public func remove(fromChat chat: ChatRoomEntity, userId: HandleEntity) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.remove(fromChat: chat.chatId, userHandle: userId, delegate: ChatRequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func loadMessages(forChat chat: ChatRoomEntity, count: Int) -> ChatSourceEntity {
        sdk.loadMessages(forChat: chat.chatId, count: count).toChatSourceEntity()
    }
    
    public func userEmail(for handle: HandleEntity) async -> String? {
        if let email = sdk.contactEmail(byHandle: handle) {
            return email
        } else {
            return await withAsyncValue { completion in
                sdk.userEmail(byUserHandle: handle, delegate: ChatRequestDelegate { result in
                    switch result {
                    case .success(let request):
                        completion(.success(request.text))
                    case .failure:
                        completion(.success(nil))
                    }
                })
            }
        }
    }

    public var chatConnectionStateUpdate: AnyAsyncSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus)> {
        chatUpdatesProvider.updates
    }
}

private final class ChatRoomUpdateListener: NSObject, MEGAChatRoomDelegate {
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
    
    func onChatRoomUpdate(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        source.send(chat.toChatRoomEntity())
    }
}

private final class ChatRoomMessageLoadedListener: NSObject, MEGAChatRoomDelegate {
    private let sdk: MEGAChatSdk
    let chatId: HandleEntity
    
    private let source = PassthroughSubject<ChatMessageEntity?, Never>()
    
    var monitor: AnyPublisher<ChatMessageEntity?, Never> {
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
    
    func onMessageLoaded(_ api: MEGAChatSdk, message: MEGAChatMessage?) {
        source.send(message?.toChatMessageEntity())
    }
}

private class ChatRoomDelegateDTO: NSObject, MEGAChatRoomDelegate {
    private let chatId: ChatIdEntity
    private let chatRoomDelegate: ChatRoomDelegateEntity
    
    init(chatId: ChatIdEntity, chatRoomDelegate: ChatRoomDelegateEntity) {
        self.chatId = chatId
        self.chatRoomDelegate = chatRoomDelegate
        super.init()
        MEGAChatSdk.sharedChatSdk.addChatRoomDelegate(chatId, delegate: self)
    }
    
    deinit {
        MEGAChatSdk.sharedChatSdk.removeChatRoomDelegate(chatId, delegate: self)
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        chatRoomDelegate.onChatRoomUpdate?(chat.toChatRoomEntity())
    }
    
    func onMessageLoaded(_ api: MEGAChatSdk, message: MEGAChatMessage?) {
        chatRoomDelegate.onMessageLoaded?(message?.toChatMessageEntity())
    }
    
    func onMessageReceived(_ api: MEGAChatSdk, message: MEGAChatMessage) {
        chatRoomDelegate.onMessageReceived?(message.toChatMessageEntity())
    }
    
    func onMessageUpdate(_ api: MEGAChatSdk, message: MEGAChatMessage) {
        chatRoomDelegate.onMessageUpdate?(message.toChatMessageEntity())
    }
    
    func onHistoryReloaded(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        chatRoomDelegate.onHistoryReloaded?(chat.toChatRoomEntity())
    }
    
    func onReactionUpdate(_ api: MEGAChatSdk, messageId: UInt64, reaction: String, count: Int) {
        chatRoomDelegate.onReactionUpdate?(messageId, reaction, count)
    }
}

private extension MEGAChatSdk {
    func createChatRoom(userHandle: UInt64, completion: @escaping(Result<MEGAChatRoom, ChatRoomErrorEntity>) -> Void) {
        let peerList = MEGAChatPeerList()
        peerList.addPeer(withHandle: userHandle, privilege: MEGAChatRoomPrivilege.standard.rawValue)
        
        let delegate = ChatRequestDelegate { [weak self] result in
            guard
                case .success(let request) = result,
                let self,
                let chatRoom = self.chatRoom(forChatId: request.chatHandle)
            else {
                completion(.failure(.generic))
                return
            }
            
            completion(.success(chatRoom))
        }
        
        createChatGroup(false, peers: peerList, delegate: delegate)
    }
}
