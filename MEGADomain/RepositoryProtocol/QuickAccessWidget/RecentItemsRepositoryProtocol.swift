import Foundation

protocol RecentItemsRepositoryProtocol {
    func deleteAllRecentItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    @available(iOS 14.0, *)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func fetchAllRecentItems() -> [RecentItemEntity]
}
