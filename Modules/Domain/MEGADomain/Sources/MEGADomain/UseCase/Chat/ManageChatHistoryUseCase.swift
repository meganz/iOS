
public struct ManageChatHistoryUseCase {
    public let retentionValueUseCase: any HistoryRetentionUseCaseProtocol
    public let historyRetentionUseCase: any HistoryRetentionUseCaseProtocol
    public let clearChatHistoryUseCase: any ClearChatHistoryUseCaseProtocol
    
    public init(retentionValueUseCase: any HistoryRetentionUseCaseProtocol,
                historyRetentionUseCase: any HistoryRetentionUseCaseProtocol,
                clearChatHistoryUseCase: any ClearChatHistoryUseCaseProtocol) {
        self.retentionValueUseCase = retentionValueUseCase
        self.historyRetentionUseCase = historyRetentionUseCase
        self.clearChatHistoryUseCase = clearChatHistoryUseCase
    }
}
