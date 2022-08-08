import Foundation
import MEGADomain

class RecentItemsRepository: RecentItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func deleteAllRecentItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        store.deleteQuickAccessRecentItems(completion: completion)
    }
    
    func insertRecentItem(_ item: RecentItemEntity) {
        store.insertQuickAccessRecentItem(withBase64Handle: item.base64Handle, name: item.name, isUpdate: item.isUpdate, timestamp: item.timestamp)
    }
    
    @available(iOS 14.0, *)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        store.batchInsertQuickAccessRecentItems(items, completion: completion)
    }
    
    func fetchAllRecentItems() -> [RecentItemEntity] {
        store.fetchAllQuickAccessRecentItem()
    }
}
