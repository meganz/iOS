
public protocol HistoryRetentionUseCaseProtocol {
    func chatRetentionTime(for chatId: ChatIdEntity, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
    func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
}

public struct HistoryRetentionUseCase<T: ManageChatHistoryRepositoryProtocol>: HistoryRetentionUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func chatRetentionTime(for chatId: ChatIdEntity, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        repository.chatRetentionTime(for: chatId, completion: completion)
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        repository.setChatRetentionTime(for: chatId, period: period, completion: completion)
    }
}
