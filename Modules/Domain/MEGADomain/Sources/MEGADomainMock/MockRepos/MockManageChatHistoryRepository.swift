import MEGADomain

public struct MockManageChatHistoryRepository: ManageChatHistoryRepositoryProtocol {
    private let chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>)
    private let setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>)
    private let clearChatHistory: (Result<Void, ManageChatHistoryErrorEntity>)
    
    public init(chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic),
                setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic),
                clearChatHistory: (Result<Void, ManageChatHistoryErrorEntity>) = .failure(.generic)) {
        self.chatRetentionTime = chatRetentionTime
        self.setChatRetentionTime = setChatRetentionTime
        self.clearChatHistory = clearChatHistory
    }
    
    public func chatRetentionTime(for chatId: ChatIdEntity, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(chatRetentionTime)
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        completion(setChatRetentionTime)
    }
    
    public func clearChatHistory(for chatId: ChatIdEntity, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void) {
        completion(clearChatHistory)
    }
    
}
