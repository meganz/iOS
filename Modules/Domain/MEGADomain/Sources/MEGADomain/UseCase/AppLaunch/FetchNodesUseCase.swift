import MEGASwift

public protocol FetchNodesUseCaseProtocol: Sendable {
    func fetchNodes() throws -> AnyAsyncSequence<RequestEventEntity>
}

public final class FetchNodesUseCase: FetchNodesUseCaseProtocol {
    private let repository: any FetchNodesRepositoryProtocol
    
    public init(repository: some FetchNodesRepositoryProtocol) {
        self.repository = repository
    }
    
    public func fetchNodes() throws -> AnyAsyncSequence<RequestEventEntity> {
        try repository.fetchNodes()
    }
}
