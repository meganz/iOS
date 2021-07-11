import Foundation

protocol RecentNodesRepositoryProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void)
}
