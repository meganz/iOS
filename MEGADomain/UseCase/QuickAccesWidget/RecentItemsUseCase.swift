
import Foundation

// MARK: - Use case protocol -
protocol RecentItemsUseCaseProtocol {
    func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    func fetchRecentItems() -> [RecentItemEntity]
}

struct RecentItemsUseCase: RecentItemsUseCaseProtocol {
    
    private let repo: RecentItemsRepositoryProtocol

    init(repo: RecentItemsRepositoryProtocol) {
        self.repo = repo
    }
    
    func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        repo.deleteAllRecentItems { (result) in
            switch result {
            case .success(_):
                items.forEach {
                    repo.insertRecentItem($0)
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func insertRecentItem(_ item: RecentItemEntity) {
        repo.insertRecentItem(item)
    }
    
    func fetchRecentItems() -> [RecentItemEntity] {
        return repo.fetchAllRecentItems()
    }
}
