public protocol RecentItemsUseCaseProtocol: Sendable {
    func resetRecentItems(by items: [RecentItemEntity]) async throws
    func insertRecentItem(_ item: RecentItemEntity)
    func batchInsertRecentItems(_ items: [RecentItemEntity]) async throws
    func fetchRecentItems() -> [RecentItemEntity]
}

public struct RecentItemsUseCase<T: RecentItemsRepositoryProtocol>: RecentItemsUseCaseProtocol {
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    public func resetRecentItems(by items: [RecentItemEntity]) async throws {
        try await repo.deleteAllRecentItems()
        try await repo.batchInsertRecentItems(items)
    }
    
    public func insertRecentItem(_ item: RecentItemEntity) {
        repo.insertRecentItem(item)
    }
    
    public func batchInsertRecentItems(_ items: [RecentItemEntity]) async throws {
        try await repo.batchInsertRecentItems(items)
    }

    public func fetchRecentItems() -> [RecentItemEntity] {
        return repo.fetchAllRecentItems()
    }
}
