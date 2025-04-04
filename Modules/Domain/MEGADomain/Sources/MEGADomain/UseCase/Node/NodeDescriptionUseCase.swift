public protocol NodeDescriptionUseCaseProtocol: Sendable {
    func update(description: String?, for node: NodeEntity) async throws -> NodeEntity
}

public struct NodeDescriptionUseCase<T: NodeDescriptionRepositoryProtocol>: NodeDescriptionUseCaseProtocol {
    private let repository: T

    public init(repository: T) {
        self.repository = repository
    }

    public func update(description: String?, for node: NodeEntity) async throws -> NodeEntity {
        try await repository.update(description: description, for: node)
    }
}
