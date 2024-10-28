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
    
    public func chatRetentionTime(for chatId: ChatIdEntity) async throws -> UInt {
        try chatRetentionTime.get()
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt {
        try setChatRetentionTime.get()
    }
    
    public func clearChatHistory(for chatId: ChatIdEntity) async throws {
        try clearChatHistory.get()
    }
}
