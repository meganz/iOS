import Foundation

protocol RecentNodesRepositoryProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[MEGARecentActionBucket], QuickAccessWidgetErrorEntity>) -> Void)
}
