@testable import MEGA

struct MockManageChatHistoryRepository: ManageChatHistoryRepositoryProtocol {
    var chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    var setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    var clearChatHistory: (Result<Void, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    func chatRetentionTime(for chatId: ChatId, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(chatRetentionTime)
    }
    
    func setChatRetentionTime(for chatId: ChatId, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(setChatRetentionTime)
    }
    
    func clearChatHistory(for chatId: ChatId, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void) {
        completion(clearChatHistory)
    }
    
    
}
