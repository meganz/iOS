import MEGADomain

public struct MockNodeDescriptionUseCase: NodeDescriptionUseCaseProtocol {
    private let result: Result<NodeEntity, any Error>

    public init(result: Result<NodeEntity, any Error> = .success(NodeEntity())) {
        self.result = result
    }

    public func update(description: String?, for node: NodeEntity) async throws -> NodeEntity {
        try result.get()
    }
}
