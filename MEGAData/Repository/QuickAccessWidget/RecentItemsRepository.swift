
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
        store.fetchAllQuickAccessRecentItem().compactMap {
            guard let handle = $0.handle,
                  let name = $0.name,
                  let date = $0.timestamp,
                  let isUpdate = $0.isUpdate else {
                return nil
            }
            
            return RecentItemEntity(base64Handle: handle, name: name, timestamp: date, isUpdate: isUpdate.boolValue)
        }
    }
}
