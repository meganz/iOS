public protocol ChatNodeRepositoryProtocol: RepositoryProtocol, Sendable {
    func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async -> NodeEntity?
}
