
import Foundation

// MARK: - Use case protocol -
protocol ClearChatHistoryUseCaseProtocol {
    func clearChatHistory(for chatId: ChatId, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct ClearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol {
    private let repository: ManageChatHistoryRepositoryProtocol
    
    init(repository: ManageChatHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    func clearChatHistory(for chatId: ChatId, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void) {
        repository.clearChatHistory(for: chatId, completion: completion)
    }
}
