public protocol ImportNodeRepositoryProtocol: RepositoryProtocol, Sendable {
    func importChatNode(
        _ node: NodeEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async throws -> NodeEntity
}
