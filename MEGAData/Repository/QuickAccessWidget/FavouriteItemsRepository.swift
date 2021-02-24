
import Foundation

class FavouriteItemsRepository: FavouriteItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    private lazy var context: NSManagedObjectContext? = store.childPrivateQueueContext
    
    func deleteAllFavouriteItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        if let context = context {
            store.deleteQuickAccessFavouriteItems(with: context, completion: completion)
        } else {
            completion(.failure(.megaStore))
        }
    }
    
    func insertFavouriteItem(_ item: FavouriteItemEntity) {
        if let context = context {
            store.insertQuickAccessFavouriteItem(withBase64Handle: item.base64Handle, name: item.name, timestamp: item.timestamp, context: context)
        }
    }
    
    func deleteFavouriteItem(with base64Handle: String) {
        if let context = context {
            store.deleteQuickAccessFavouriteItem(withBase64Handle: base64Handle, inContext: context)
        }
    }
    
    func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        if let context = context {
            guard let quickAccessWidgetFavouriteItems = store.fetchAllQuickAccessFavouriteItems(context: context) else {
                return []
            }
            
            return quickAccessWidgetFavouriteItems.map {
                FavouriteItemEntity(base64Handle: $0.handle, name: $0.name, timestamp: $0.timestamp)
            }
        } else {
            return []
        }
    }
    
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        if let context = context {
            guard let quickAccessWidgetFavouriteItems = store.fetchQuickAccessFavourtieItems(withLimit: count, context: context) else {
                return []
            }
            
            return quickAccessWidgetFavouriteItems.map {
                FavouriteItemEntity(base64Handle: $0.handle, name: $0.name, timestamp: $0.timestamp)
            }
        } else {
            return []
        }
    }

}
