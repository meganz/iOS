
public protocol ImportNodeRepositoryProtocol: RepositoryProtocol {
    func importChatNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<NodeEntity, ExportFileErrorEntity>) -> Void)
}
