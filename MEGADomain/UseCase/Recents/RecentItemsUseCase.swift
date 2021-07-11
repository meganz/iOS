
import Foundation

// MARK: - Use case protocol -
protocol RecentItemsUseCaseProtocol {
    @available(iOS 14.0, *)
    func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    @available(iOS 14.0, *)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func fetchRecentItems() -> [RecentItemEntity]
}

struct RecentItemsUseCase: RecentItemsUseCaseProtocol {
    private let repo: RecentItemsRepositoryProtocol

    init(repo: RecentItemsRepositoryProtocol) {
        self.repo = repo
    }
    
    @available(iOS 14.0, *)
    func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        repo.deleteAllRecentItems { (result) in
            switch result {
            case .success(_):
                repo.batchInsertRecentItems(items) { insertResult in
                    completion(insertResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func insertRecentItem(_ item: RecentItemEntity) {
        repo.insertRecentItem(item)
    }
    
    @available(iOS 14.0, *)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        repo.batchInsertRecentItems(items, completion: completion)
    }
    
    func fetchRecentItems() -> [RecentItemEntity] {
        return repo.fetchAllRecentItems()
    }
}
