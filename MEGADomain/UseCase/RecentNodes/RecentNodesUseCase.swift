import Foundation

protocol RecentNodesUseCaseProtocol {
    func recentActionBuckets(completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void)
}

struct RecentNodesUseCase: RecentNodesUseCaseProtocol {
    
    private let repo: RecentNodesRepositoryProtocol

    init(repo: RecentNodesRepositoryProtocol) {
        self.repo = repo
    }
    func recentActionBuckets(completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.recentActionBuckets(completion: completion)
    }
    
}
