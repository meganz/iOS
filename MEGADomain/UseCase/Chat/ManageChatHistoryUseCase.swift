
import Foundation

// MARK: - Use case -
struct ManageChatHistoryUseCase {
    let retentionValueUseCase: HistoryRetentionUseCaseProtocol
    let historyRetentionUseCase: HistoryRetentionUseCaseProtocol
    let clearChatHistoryUseCase: ClearChatHistoryUseCaseProtocol
}
