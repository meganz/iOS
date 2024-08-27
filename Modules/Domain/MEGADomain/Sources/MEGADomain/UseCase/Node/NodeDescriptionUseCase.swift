public protocol NodeDescriptionUseCaseProtocol: Sendable {
    func update(description: String?, for node: NodeEntity) async throws -> NodeEntity
}

public struct NodeDescriptionUseCase: NodeDescriptionUseCaseProtocol {
    private let repository: NodeDescriptionRepositoryProtocol

    public init(repository: NodeDescriptionRepositoryProtocol) {
        self.repository = repository
    }

    public func update(description: String?, for node: NodeEntity) async throws -> NodeEntity {
        try await repository.update(description: description, for: node)
    }
}
