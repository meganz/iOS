public protocol ManageChatHistoryRepositoryProtocol: Sendable {    
    func chatRetentionTime(for chatId: ChatIdEntity) async throws -> UInt
    func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt
    func clearChatHistory(for chatId: ChatIdEntity) async throws
}
