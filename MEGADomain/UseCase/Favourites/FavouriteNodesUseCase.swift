
import Foundation

protocol FavouriteNodesUseCaseProtocol {
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void)
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void)
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void)
    func unregisterOnNodesUpdate() -> Void
}

struct FavouriteNodesUseCase<T: FavouriteNodesRepositoryProtocol>: FavouriteNodesUseCaseProtocol {
    
    private let repo: T

    init(repo: T) {
        self.repo = repo
    }
    
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getAllFavouriteNodes(completion: completion)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getFavouriteNodes(limitCount: limitCount, completion: completion)
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        repo.registerOnNodesUpdate(callback: callback)
    }
    
    func unregisterOnNodesUpdate() -> Void {
        repo.unregisterOnNodesUpdate()
    }
}
