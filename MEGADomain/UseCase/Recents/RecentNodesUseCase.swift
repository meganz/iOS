import Foundation

protocol RecentNodesUseCaseProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void)
}

struct RecentNodesUseCase<T: RecentNodesRepositoryProtocol>: RecentNodesUseCaseProtocol {
    private let repo: T

    init(repo: T) {
        self.repo = repo
    }
    
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getAllRecentActionBuckets(completion: completion)
    }
    
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getRecentActionBuckets(limitCount: limitCount, completion: completion)
    }
}
