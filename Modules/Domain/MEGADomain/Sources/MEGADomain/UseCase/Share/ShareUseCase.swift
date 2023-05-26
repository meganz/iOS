public protocol ShareUseCaseProtocol {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
    func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity]
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
    
    public func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            nodes.forEach { node in
                group.addTask {
                    return try await repo.createShareKey(forNode: node)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })
        }
    }
}
