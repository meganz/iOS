import MEGADomain

public struct MockImportNodeRepository: ImportNodeRepositoryProtocol {
    public static let newRepo = MockImportNodeRepository()

    private let result: Result<NodeEntity, any Error>

    public init(result: Result<NodeEntity, any Error> = .failure(TransferErrorEntity.couldNotFindNodeByHandle)) {
        self.result = result
    }

    public func importChatNode(
        _ node: NodeEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async throws -> NodeEntity {
        try result.get()
    }
}
