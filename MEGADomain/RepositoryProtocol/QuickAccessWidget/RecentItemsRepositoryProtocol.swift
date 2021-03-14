import Foundation

protocol RecentItemsRepositoryProtocol {
    func deleteAllRecentItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    func fetchAllRecentItems() -> [RecentItemEntity]
}
