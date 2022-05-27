@testable import MEGA

struct MockHistoryRetentionUseCase: HistoryRetentionUseCaseProtocol {
    var chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    var setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    func chatRetentionTime(for chatId: ChatId, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(chatRetentionTime)
    }
    
    func setChatRetentionTime(for chatId: ChatId, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(setChatRetentionTime)
    }
}
