
public struct ManageChatHistoryUseCase {
    public let retentionValueUseCase: HistoryRetentionUseCaseProtocol
    public let historyRetentionUseCase: HistoryRetentionUseCaseProtocol
    public let clearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol
    
    public init(retentionValueUseCase: HistoryRetentionUseCaseProtocol, historyRetentionUseCase: HistoryRetentionUseCaseProtocol, clearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol) {
        self.retentionValueUseCase = retentionValueUseCase
        self.historyRetentionUseCase = historyRetentionUseCase
        self.clearChatHistoryUseCase = clearChatHistoryUseCase
    }
}
