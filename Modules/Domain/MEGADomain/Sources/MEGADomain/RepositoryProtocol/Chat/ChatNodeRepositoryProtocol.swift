public protocol ChatNodeRepositoryProtocol: RepositoryProtocol {
    func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async -> NodeEntity?
}
