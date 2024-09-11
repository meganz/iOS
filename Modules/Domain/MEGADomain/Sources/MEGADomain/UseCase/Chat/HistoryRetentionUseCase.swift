public protocol HistoryRetentionUseCaseProtocol: Sendable {
    func chatRetentionTime(for chatId: ChatIdEntity) async throws -> UInt
    func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt
}

public struct HistoryRetentionUseCase<T: ManageChatHistoryRepositoryProtocol>: HistoryRetentionUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func chatRetentionTime(for chatId: ChatIdEntity) async throws -> UInt {
        try await repository.chatRetentionTime(for: chatId)
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt {
        try await repository.setChatRetentionTime(for: chatId, period: period)
    }
}
