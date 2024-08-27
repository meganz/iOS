public protocol NodeDescriptionRepositoryProtocol: RepositoryProtocol, Sendable {
    func update(description: String?, for node: NodeEntity) async throws -> NodeEntity
}
