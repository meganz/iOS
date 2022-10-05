import Combine

// MARK: - Use case protocol -
public protocol ChatUseCaseProtocol {
    func chatStatus() -> ChatStatusEntity
    func changeChatStatus(to status: ChatStatusEntity)
    func monitorSelfChatStatusChange() -> AnyPublisher<ChatStatusEntity, Never>
    func existsActiveCall() -> Bool
}

// MARK: - Use case implementation -
public struct ChatUseCase<T: ChatRepositoryProtocol>: ChatUseCaseProtocol {
    private var chatRepo: T

    public init(chatRepo: T) {
        self.chatRepo = chatRepo
    }
    
    public func chatStatus() -> ChatStatusEntity {
        chatRepo.chatStatus()
    }
    
    public func changeChatStatus(to status: ChatStatusEntity) {
        chatRepo.changeChatStatus(to: status)
    }
    
    public func monitorSelfChatStatusChange() -> AnyPublisher<ChatStatusEntity, Never> {
        chatRepo.monitorSelfChatStatusChange()
    }
    
    public func existsActiveCall() -> Bool {
        chatRepo.existsActiveCall()
    }
}
