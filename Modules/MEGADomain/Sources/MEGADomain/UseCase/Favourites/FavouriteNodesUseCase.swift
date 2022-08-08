import Foundation

public protocol FavouriteNodesUseCaseProtocol {
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void)
    func unregisterOnNodesUpdate() -> Void
}

public struct FavouriteNodesUseCase<T: FavouriteNodesRepositoryProtocol>: FavouriteNodesUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.allFavouriteNodes(searchString: searchString, completion: completion)
    }
    
    @available(*, renamed: "allFavouriteNodes()")
    public func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getAllFavouriteNodes(completion: completion)
    }
    
    public func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getFavouriteNodes(limitCount: limitCount, completion: completion)
    }
    
    public func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        repo.registerOnNodesUpdate(callback: callback)
    }
    
    public func unregisterOnNodesUpdate() -> Void {
        repo.unregisterOnNodesUpdate()
    }
}
