import Foundation

// MARK: - Use case protocol -
public protocol FavouriteItemsUseCaseProtocol {
    func createFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func deleteFavouriteItem(with base64Handle: Base64HandleEntity)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}

public struct FavouriteItemsUseCase<T: FavouriteItemsRepositoryProtocol>: FavouriteItemsUseCaseProtocol {
    
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }

    public func createFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        repo.deleteAllFavouriteItems { (result) in
            switch result {
            case .success():
                repo.batchInsertFavouriteItems(items) { insertResult in
                    completion(insertResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteFavouriteItem(with base64Handle: Base64HandleEntity) {
        repo.deleteFavouriteItem(with: base64Handle)
    }
    
    public func insertFavouriteItem(_ item: FavouriteItemEntity) {
        repo.insertFavouriteItem(item)
    }
    
    public func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        repo.batchInsertFavouriteItems(items, completion: completion)
    }
    
    public func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        return repo.fetchAllFavouriteItems()
    }
    
    public func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        return repo.fetchFavouriteItems(upTo: count)
    }
}
