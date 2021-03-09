import Foundation

protocol RecentNodesUseCaseProtocol {
    func recentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void)
}

struct RecentNodesUseCase: RecentNodesUseCaseProtocol {
    
    private let repo: RecentNodesRepositoryProtocol

    init(repo: RecentNodesRepositoryProtocol) {
        self.repo = repo
    }
    func recentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.recentActionBuckets(completion: completion)
    }
    
}
