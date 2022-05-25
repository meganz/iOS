
import Foundation

protocol FavouriteNodesUseCaseProtocol {
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func favouriteAlbum(withCUHandle handle: MEGAHandle?) async throws -> AlbumEntity
    func favouriteAlbumMediaNodes(withCUHandle handle: MEGAHandle?) async throws -> [NodeEntity]
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
    /// - Parameter handle: CU node handle, which is used for filtering video nodes
    /// - Returns: Album Entity
    func favouriteAlbum(withCUHandle handle: MEGAHandle?) async throws -> AlbumEntity {
        let nodes = try await favouriteAlbumMediaNodes(withCUHandle: handle)
        
        return AlbumEntity(handle: nil, coverNode: nodes.first, numberOfNodes: nodes.count)
    }
    
    /// Get all favourites images from Cloud Drive and video nodes from Camerea Upload only
    /// - Parameter handle: CU handle, used for filtering video nodes
    /// - Returns: All valid media type favourites nodes
    func favouriteAlbumMediaNodes(withCUHandle handle: MEGAHandle?) async throws -> [NodeEntity] {
        var nodes = try await repo.allFavouritesNodes()

        nodes = nodes.filter({
            return ($0.name as NSString?)?.mnz_isImagePathExtension == true || ($0.name as NSString?)?.mnz_isVideoPathExtension == true && $0.parentHandle == handle
        })
        
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
