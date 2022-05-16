
import Foundation

protocol FavouriteNodesUseCaseProtocol {
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getFavouriteAlbum(fromParent parent: NodeEntity) async throws -> AlbumEntity
    func getFavouriteNodes(fromParent parent: NodeEntity) async throws -> [NodeEntity]
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void)
    func unregisterOnNodesUpdate() -> Void
}

struct FavouriteNodesUseCase<T: FavouriteNodesRepositoryProtocol>: FavouriteNodesUseCaseProtocol {
    
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getAllFavouriteNodes(completion: completion)
    }
    
    /// Load favourites album cover node(this method will be remove when SDK album api is ready)
    /// - Parameter parent: CU folder
    /// - Returns: Favourites album entity
    func getFavouriteAlbum(fromParent parent: NodeEntity) async throws -> AlbumEntity {
        let nodes = try await getFavouriteNodes(fromParent: parent)
        
        return AlbumEntity(coverNode: nodes.first, numberOfNodes: nodes.count)
    }
    
    func getFavouriteNodes(fromParent parent: NodeEntity) async throws -> [NodeEntity] {
        var nodes = try await repo.getFavouritesNodes(fromParent: parent)
        nodes = nodes.sorted { $0.modificationTime >= $1.modificationTime }
        
        return nodes
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        repo.getFavouriteNodes(limitCount: limitCount, completion: completion)
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        repo.registerOnNodesUpdate(callback: callback)
    }
    
    func unregisterOnNodesUpdate() -> Void {
        repo.unregisterOnNodesUpdate()
    }
}
