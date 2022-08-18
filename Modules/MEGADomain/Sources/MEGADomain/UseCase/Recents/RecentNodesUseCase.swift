public protocol RecentNodesUseCaseProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void)
}

public struct RecentNodesUseCase<T: RecentNodesRepositoryProtocol>: RecentNodesUseCaseProtocol {
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    public func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getAllRecentActionBuckets(completion: completion)
    }
    
    public func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getRecentActionBuckets(limitCount: limitCount, completion: completion)
    }
}
