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
        switch chatRetentionTime {
        case .success(let successValue):
            successValue
        case .failure(let error):
            throw error
        }
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt {
        switch setChatRetentionTime {
        case .success(let successValue):
            successValue
        case .failure(let error):
            throw error
        }
    }
    
    public func clearChatHistory(for chatId: ChatIdEntity) async throws {
        switch clearChatHistory {
        case .success(let successValue):
            successValue
        case .failure(let error):
            throw error
        }
    }
}
