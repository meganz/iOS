public protocol ShareUseCaseProtocol {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
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
}
