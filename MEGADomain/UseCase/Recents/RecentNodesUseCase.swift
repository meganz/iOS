import Foundation

protocol RecentNodesUseCaseProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void)
}

struct RecentNodesUseCase<T: RecentNodesRepositoryProtocol>: RecentNodesUseCaseProtocol {
    private let repo: T

    init(repo: T) {
        self.repo = repo
    }
    
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getAllRecentActionBuckets(completion: completion)
    }
    
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getRecentActionBuckets(limitCount: limitCount, completion: completion)
    }
}
