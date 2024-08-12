import Foundation

public protocol FavouriteItemsRepositoryProtocol: Sendable {
    func deleteAllFavouriteItems() async throws
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity]) async throws
    func deleteFavouriteItem(with base64Handle: String)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}
