public protocol RecentItemsUseCaseProtocol: Sendable {
    func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func fetchRecentItems() -> [RecentItemEntity]
}

public struct RecentItemsUseCase<T: RecentItemsRepositoryProtocol>: RecentItemsUseCaseProtocol {
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    public func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        repo.deleteAllRecentItems { (result) in
            switch result {
            case .success:
                repo.batchInsertRecentItems(items) { insertResult in
                    completion(insertResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func insertRecentItem(_ item: RecentItemEntity) {
        repo.insertRecentItem(item)
    }
    
    public func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        repo.batchInsertRecentItems(items, completion: completion)
    }
    
    public func fetchRecentItems() -> [RecentItemEntity] {
        return repo.fetchAllRecentItems()
    }
}
