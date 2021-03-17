import Foundation

protocol RecentNodesUseCaseProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void)
}

struct RecentNodesUseCase: RecentNodesUseCaseProtocol {
    private let repo: RecentNodesRepositoryProtocol

    init(repo: RecentNodesRepositoryProtocol) {
        self.repo = repo
    }
    
    func getAllRecentActionBuckets(completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getAllRecentActionBuckets(completion: completion)
    }
    
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getRecentActionBuckets(limitCount: limitCount, completion: completion)
    }
}
