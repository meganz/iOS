import Foundation

// MARK: - Use case protocol -
protocol FavouriteItemsUseCaseProtocol {
    func createFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
    func insertFavouriteItem(_ item: FavouriteItemEntity)
    func deleteFavouriteItem(with base64Handle: MEGABase64Handle)
    func fetchAllFavouriteItems() -> [FavouriteItemEntity]
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity]
}

struct FavouriteItemsUseCase: FavouriteItemsUseCaseProtocol {
    
    private let repo: FavouriteItemsRepositoryProtocol

    init(repo: FavouriteItemsRepositoryProtocol) {
        self.repo = repo
    }

    func createFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        repo.deleteAllFavouriteItems { (result) in
            switch result {
            case .success():
                items.forEach {
                    repo.insertFavouriteItem($0)
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deleteFavouriteItem(with base64Handle: MEGABase64Handle) {
        repo.deleteFavouriteItem(with: base64Handle)
    }
    
    func insertFavouriteItem(_ item: FavouriteItemEntity) {
        repo.insertFavouriteItem(item)
    }
    
    func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        return repo.fetchAllFavouriteItems()
    }
    
    func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        return repo.fetchFavouriteItems(upTo: count)
    }
}
