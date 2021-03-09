
import Foundation

class FavouriteItemsRepository: FavouriteItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func deleteAllFavouriteItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        store.deleteQuickAccessFavouriteItems(completion: completion)
    }
    
    func insertFavouriteItem(_ item: FavouriteItemEntity) {
        store.insertQuickAccessFavouriteItem(withBase64Handle: item.base64Handle, name: item.name, timestamp: item.timestamp)
    }
    
    func deleteFavouriteItem(with base64Handle: String) {
        store.deleteQuickAccessFavouriteItem(withBase64Handle: base64Handle)
    }
    
    func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        store.fetchAllQuickAccessFavouriteItems().map {
            FavouriteItemEntity(base64Handle: $0.handle, name: $0.name, timestamp: $0.timestamp)
        }
    }
    
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        store.fetchQuickAccessFavourtieItems(withLimit: count).map {
            FavouriteItemEntity(base64Handle: $0.handle, name: $0.name, timestamp: $0.timestamp)
        }
    }
    
}
