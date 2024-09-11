import MEGADomain

public struct MockClearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol {
    var clearChatHistory: (Result<Void, ManageChatHistoryErrorEntity>) = .failure(.generic)
    
    public func clearChatHistory(for chatId: ChatIdEntity) async throws {
        switch clearChatHistory {
        case .success(let successValue):
            successValue
        case .failure(let error):
            throw error
        }
    }
}
