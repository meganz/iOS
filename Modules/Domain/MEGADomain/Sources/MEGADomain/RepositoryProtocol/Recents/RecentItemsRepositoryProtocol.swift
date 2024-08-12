import Foundation

public protocol RecentItemsRepositoryProtocol: Sendable {
    func deleteAllRecentItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func fetchAllRecentItems() -> [RecentItemEntity]
}
