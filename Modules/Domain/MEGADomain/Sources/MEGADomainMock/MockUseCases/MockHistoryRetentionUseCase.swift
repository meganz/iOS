import MEGADomain

public struct MockHistoryRetentionUseCase: HistoryRetentionUseCaseProtocol {
    var chatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    var setChatRetentionTime: (Result<UInt, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
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
}
