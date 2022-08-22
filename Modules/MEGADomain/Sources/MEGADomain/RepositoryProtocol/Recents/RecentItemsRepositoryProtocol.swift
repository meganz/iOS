import Foundation

public protocol RecentItemsRepositoryProtocol {
    func deleteAllRecentItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    @available(iOS 14.0, *)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func fetchAllRecentItems() -> [RecentItemEntity]
}
