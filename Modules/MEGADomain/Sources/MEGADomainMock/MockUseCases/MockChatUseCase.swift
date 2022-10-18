import MEGADomain
import Combine

public final class MockChatUseCase: ChatUseCaseProtocol {
    public var fullName: String?
    public var status: ChatStatusEntity
    public var callInProgress: Bool
    public var statusChangePublisher: PassthroughSubject<ChatStatusEntity, Never>
    public var chatListItemUpdatePublisher: PassthroughSubject<ChatListItemEntity, Never>
    public var items: [ChatListItemEntity]?
    public var archivedChatsCount: UInt = 0
    
    public init(
        fullName: String? = nil,
        status: ChatStatusEntity = .offline,
        callInProgress: Bool = false,
        statusChangePublisher: PassthroughSubject<ChatStatusEntity, Never> = PassthroughSubject<ChatStatusEntity, Never>(),
        chatListItemUpdatePublisher:  PassthroughSubject<ChatListItemEntity, Never> =  PassthroughSubject<ChatListItemEntity, Never>(),
        items: [ChatListItemEntity]? = []
    ) {
        self.fullName = fullName
        self.status = status
        self.callInProgress = callInProgress
        self.statusChangePublisher = statusChangePublisher
        self.chatListItemUpdatePublisher = chatListItemUpdatePublisher
        self.items = items
    }
    
    public func chatStatus() -> ChatStatusEntity {
        status
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        self.status = status
    }
    
    public func monitorChatStatusChange(forUserHandle userHandle: HandleEntity) -> AnyPublisher<ChatStatusEntity, Never> {
        statusChangePublisher.eraseToAnyPublisher()
    }
    
    public func monitorChatListItemUpdate() -> AnyPublisher<MEGADomain.ChatListItemEntity, Never> {
        chatListItemUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func existsActiveCall() -> Bool {
        callInProgress
    }
    
    public func chatsList(ofType type: ChatTypeEntity) -> [ChatListItemEntity]? {
        items
    }
    
    public func myFullName() -> String? {
        fullName
    }
    
    public func archivedChatListCount() -> UInt {
        archivedChatsCount
    }
}
