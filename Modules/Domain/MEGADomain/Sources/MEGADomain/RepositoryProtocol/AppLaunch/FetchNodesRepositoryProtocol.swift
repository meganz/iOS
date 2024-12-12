import MEGASwift

public protocol FetchNodesRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchNodes() throws -> AnyAsyncSequence<RequestEventEntity>
}
