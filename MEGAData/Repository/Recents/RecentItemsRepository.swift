import Foundation
import MEGADomain
import MEGASwift

final class RecentItemsRepository: RecentItemsRepositoryProtocol {
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func insertRecentItem(_ item: RecentItemEntity) {
        store.insertQuickAccessRecentItem(withBase64Handle: item.base64Handle, name: item.name, isUpdate: item.isUpdate, timestamp: item.timestamp)
    }
        
    func fetchAllRecentItems() -> [RecentItemEntity] {
        store.fetchAllQuickAccessRecentItem()
    }
    
    func deleteAllRecentItems() async throws {
        try await withAsyncThrowingValue { completion in
            store.deleteQuickAccessRecentItems { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func batchInsertRecentItems(_ items: [RecentItemEntity]) async throws {
        try await withAsyncThrowingValue { completion in
            store.batchInsertQuickAccessRecentItems(items) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
