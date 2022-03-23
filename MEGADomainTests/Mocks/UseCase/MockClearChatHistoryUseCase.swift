
@testable import MEGA

struct MockClearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol {
    var clearChatHistory: (Result<Void, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    func clearChatHistory(for chatId: ChatId, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void) {
        completion(clearChatHistory)
    }
}
