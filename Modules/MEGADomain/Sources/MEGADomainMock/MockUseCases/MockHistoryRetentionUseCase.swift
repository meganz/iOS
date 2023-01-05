
import MEGADomain

public struct MockHistoryRetentionUseCase: HistoryRetentionUseCaseProtocol {
    var chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    var setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    public func chatRetentionTime(for chatId: ChatIdEntity, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(chatRetentionTime)
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(setChatRetentionTime)
    }
}
