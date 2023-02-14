public protocol ShareUseCaseProtocol: Sendable {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
    func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity
}

public struct ShareUseCase<T: ShareRepositoryProtocol>: ShareUseCaseProtocol {
    private let repo: T
    public init(repo: T) {
        self.repo = repo
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        repo.allPublicLinks(sortBy: order)
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        repo.allOutShares(sortBy: order)
    }
    
    public func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
        try await repo.createShareKey(forNode: node)
    }
}
