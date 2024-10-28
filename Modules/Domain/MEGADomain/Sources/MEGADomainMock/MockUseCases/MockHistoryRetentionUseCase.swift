import MEGADomain

public struct MockHistoryRetentionUseCase: HistoryRetentionUseCaseProtocol {
    var chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    var setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    public func chatRetentionTime(for chatId: ChatIdEntity) async throws -> UInt {
        try chatRetentionTime.get()
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt {
        try setChatRetentionTime.get()
    }
}
