
import Foundation

class RecentItemsRepository: RecentItemsRepositoryProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    private lazy var context: NSManagedObjectContext? = store.childPrivateQueueContext
    
    func deleteAllRecentItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        if let context = context {
            store.deleteQuickAccessRecentItems(with: context, completion: completion)
        } else {
            completion(.failure(.megaStore))
        }
    }
    
    func insertRecentItem(_ item: RecentItemEntity) {
        if let context = context {
            store.insertQuickAccessRecentItem(withBase64Handle: item.base64Handle, name: item.name, isUpdate: item.isUpdate, timestamp: item.timestamp, context: context)
        }
    }
    
    func fetchAllRecentItems() -> [RecentItemEntity] {
        if let context = context {
            guard let quickAccessWidgetRecentItems = store.fetchAllQuickAccessRecentItem(context: context) else {
                return []
            }
            
            return quickAccessWidgetRecentItems.map {
                RecentItemEntity(base64Handle: $0.handle, name: $0.name, timestamp: $0.timestamp, isUpdate: $0.isUpdate as! Bool)
            }
        } else {
            return []
        }
    }
}
