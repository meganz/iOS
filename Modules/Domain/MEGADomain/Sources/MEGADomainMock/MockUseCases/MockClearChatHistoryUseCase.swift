import MEGADomain

public struct MockClearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol {
    var clearChatHistory: (Result<Void, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    public func clearChatHistory(for chatId: ChatIdEntity) async throws {
        try clearChatHistory.get()
    }
}
