
import Foundation

// MARK: - Use case protocol -
protocol HistoryRetentionUseCaseProtocol {
    func chatRetentionTime(for chatId: ChatId, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
    func setChatRetentionTime(for chatId: ChatId, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct HistoryRetentionUseCase<T: ManageChatHistoryRepositoryProtocol>: HistoryRetentionUseCaseProtocol {
    private let repository: T
    
    init(repository: T) {
        self.repository = repository
    }
    
    func chatRetentionTime(for chatId: ChatId, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        repository.chatRetentionTime(for:chatId, completion: completion)
    }
    
    func setChatRetentionTime(for chatId: ChatId, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        repository.setChatRetentionTime(for: chatId, period: period, completion: completion)
    }
}
