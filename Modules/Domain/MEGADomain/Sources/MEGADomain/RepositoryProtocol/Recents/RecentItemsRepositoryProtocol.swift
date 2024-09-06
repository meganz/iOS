import Foundation

public protocol RecentItemsRepositoryProtocol: Sendable {
    func deleteAllRecentItems() async throws
    func insertRecentItem(_ item: RecentItemEntity)
    func batchInsertRecentItems(_ items: [RecentItemEntity]) async throws
    func fetchAllRecentItems() -> [RecentItemEntity]
}
