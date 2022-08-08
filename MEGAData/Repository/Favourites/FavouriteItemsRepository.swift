import Foundation
import MEGADomain

class FavouriteItemsRepository: FavouriteItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func deleteAllFavouriteItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        store.deleteQuickAccessFavouriteItems(completion: completion)
    }
    
    func insertFavouriteItem(_ item: FavouriteItemEntity) {
        store.insertQuickAccessFavouriteItem(withBase64Handle: item.base64Handle, name: item.name, timestamp: item.timestamp)
    }
    
    @available(iOS 14.0, *)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        store.batchInsertQuickAccessFavouriteItems(items, completion: completion)
    }
    
    func deleteFavouriteItem(with base64Handle: String) {
        store.deleteQuickAccessFavouriteItem(withBase64Handle: base64Handle)
    }
    
    func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        store.fetchAllQuickAccessFavouriteItems()
    }
    
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        store.fetchQuickAccessFavourtieItems(withLimit: count)
    }
    
}
