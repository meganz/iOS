public protocol RecentItemsUseCaseProtocol {
    @available(iOS 14.0, *)
    func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertRecentItem(_ item: RecentItemEntity)
    @available(iOS 14.0, *)
    func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func fetchRecentItems() -> [RecentItemEntity]
}

public struct RecentItemsUseCase<T: RecentItemsRepositoryProtocol>: RecentItemsUseCaseProtocol {
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    @available(iOS 14.0, *)
    public func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
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
    
    public func insertRecentItem(_ item: RecentItemEntity) {
        repo.insertRecentItem(item)
    }
    
    @available(iOS 14.0, *)
    public func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        repo.batchInsertRecentItems(items, completion: completion)
    }
    
    public func fetchRecentItems() -> [RecentItemEntity] {
        return repo.fetchAllRecentItems()
    }
}
