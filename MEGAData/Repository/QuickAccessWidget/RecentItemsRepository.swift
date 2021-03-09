
import Foundation

class RecentItemsRepository: RecentItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func deleteAllRecentItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        store.deleteQuickAccessRecentItems(completion: completion)
    }
    
    func insertRecentItem(_ item: RecentItemEntity) {
        store.insertQuickAccessRecentItem(withBase64Handle: item.base64Handle, name: item.name, isUpdate: item.isUpdate, timestamp: item.timestamp)
    }
    
    func fetchAllRecentItems() -> [RecentItemEntity] {
        store.fetchAllQuickAccessRecentItem().map {
            RecentItemEntity(base64Handle: $0.handle, name: $0.name, timestamp: $0.timestamp, isUpdate: $0.isUpdate.boolValue)
        }
    }
}
