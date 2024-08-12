import Foundation

// MARK: - Use case protocol -
public protocol FavouriteItemsUseCaseProtocol: Sendable {
    func createFavouriteItems(_ items: [FavouriteItemEntity]) async throws
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    func deleteFavouriteItem(with base64Handle: Base64HandleEntity)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}

public struct FavouriteItemsUseCase<T: FavouriteItemsRepositoryProtocol>: FavouriteItemsUseCaseProtocol {
    
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }

    public func createFavouriteItems(_ items: [FavouriteItemEntity]) async throws {
        try await repo.deleteAllFavouriteItems()
        try await repo.batchInsertFavouriteItems(items)
    }
    
    public func deleteFavouriteItem(with base64Handle: Base64HandleEntity) {
        repo.deleteFavouriteItem(with: base64Handle)
    }
    
    public func insertFavouriteItem(_ item: FavouriteItemEntity) {
        repo.insertFavouriteItem(item)
    }

    public func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        return repo.fetchAllFavouriteItems()
    }
    
    public func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        return repo.fetchFavouriteItems(upTo: count)
    }
}
