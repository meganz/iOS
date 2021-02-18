
import Foundation

protocol ManageChatHistoryRepositoryProtocol {
    func chatRetentionTime(for chatId: ChatId, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
    func setChatRetentionTime(for chatId: ChatId, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
    
    func clearChatHistory(for chatId: ChatId, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void)
}
