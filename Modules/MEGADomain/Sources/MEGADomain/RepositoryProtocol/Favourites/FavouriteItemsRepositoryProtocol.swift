import Foundation

public protocol FavouriteItemsRepositoryProtocol {
    func deleteAllFavouriteItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func deleteFavouriteItem(with base64Handle: String)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}
