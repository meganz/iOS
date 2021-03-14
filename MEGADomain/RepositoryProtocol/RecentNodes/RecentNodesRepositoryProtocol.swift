import Foundation

protocol RecentNodesRepositoryProtocol {
    func recentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void)
}
