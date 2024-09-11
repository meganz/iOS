public protocol ClearChatHistoryUseCaseProtocol: Sendable {
    func clearChatHistory(for chatId: ChatIdEntity) async throws
}

public struct ClearChatHistoryUseCase<T: ManageChatHistoryRepositoryProtocol>: ClearChatHistoryUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func clearChatHistory(for chatId: ChatIdEntity) async throws {
        try await repository.clearChatHistory(for: chatId)
    }
}
