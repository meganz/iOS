
public protocol ClearChatHistoryUseCaseProtocol {
    func clearChatHistory(for chatId: ChatIdEntity, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void)
}

public struct ClearChatHistoryUseCase<T: ManageChatHistoryRepositoryProtocol>: ClearChatHistoryUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func clearChatHistory(for chatId: ChatIdEntity, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void) {
        repository.clearChatHistory(for: chatId, completion: completion)
    }
}
