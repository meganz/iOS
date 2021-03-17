import Foundation

protocol FavouriteItemsRepositoryProtocol {
    func deleteAllFavouriteItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    @available(iOS 14.0, *)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func deleteFavouriteItem(with base64Handle: String)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}
