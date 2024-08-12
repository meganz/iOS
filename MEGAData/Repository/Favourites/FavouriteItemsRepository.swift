import Foundation
import MEGADomain
import MEGASwift

final class FavouriteItemsRepository: FavouriteItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func deleteAllFavouriteItems() async throws {
        try await withAsyncThrowingValue { completion in
            store.deleteQuickAccessFavouriteItems { result in
                completion(result.mapError { $0 as any Error })
            }
        }
    }
    
    func insertFavouriteItem(_ item: FavouriteItemEntity) {
        store.insertQuickAccessFavouriteItem(withBase64Handle: item.base64Handle, name: item.name, timestamp: item.timestamp)
    }
    
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity]) async throws {
        try await withAsyncThrowingValue { completion in
            store.batchInsertQuickAccessFavouriteItems(items) { result in
                completion(result.mapError { $0 as any Error })
            }
        }
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
