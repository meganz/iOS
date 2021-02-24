import Foundation

protocol RecentNodesRepositoryProtocol {
    func recentActionBuckets(completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void)
}
