
public protocol ManageChatHistoryRepositoryProtocol {
    func chatRetentionTime(for chatId: ChatIdEntity, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
    func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void)
    
    func clearChatHistory(for chatId: ChatIdEntity, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void)
}
