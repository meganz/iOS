import Foundation

protocol FavouriteItemsRepositoryProtocol {
    func deleteAllFavouriteItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    func deleteFavouriteItem(with base64Handle: String)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}
