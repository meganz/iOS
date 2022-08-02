import Foundation

// MARK: - Use case protocol -
protocol FavouriteItemsUseCaseProtocol {
    @available(iOS 14.0, *)
    func createFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    @available(iOS 14.0, *)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
    func deleteFavouriteItem(with base64Handle: Base64HandleEntity)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}

struct FavouriteItemsUseCase<T: FavouriteItemsRepositoryProtocol>: FavouriteItemsUseCaseProtocol {
    
    private let repo: T

    init(repo: T) {
        self.repo = repo
    }

    @available(iOS 14.0, *)
    func createFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
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
    
    func deleteFavouriteItem(with base64Handle: Base64HandleEntity) {
        repo.deleteFavouriteItem(with: base64Handle)
    }
    
    func insertFavouriteItem(_ item: FavouriteItemEntity) {
        repo.insertFavouriteItem(item)
    }
    
    @available(iOS 14.0, *)
    func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        repo.batchInsertFavouriteItems(items, completion: completion)
    }
    
    func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        return repo.fetchAllFavouriteItems()
    }
    
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        return repo.fetchFavouriteItems(upTo: count)
    }
}
