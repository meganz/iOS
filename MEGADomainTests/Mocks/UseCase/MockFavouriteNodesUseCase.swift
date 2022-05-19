@testable import MEGA

final class MockFavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    var getAllFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic)
    var getFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic)
    var onNodesUpdateCallback: [NodeEntity]? = [NodeEntity()]
    
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getAllFavouriteNodesResult)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getFavouriteNodesResult)
    }
    
    func favouriteAlbum(withCUHandle handle: MEGAHandle) async throws -> AlbumEntity {
        return AlbumEntity()
    }
    
    func favouriteAlbumsMediaNodes(withCUHandle handle: MEGAHandle) async throws -> [NodeEntity] {
        return []
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        guard let onNodesUpdateCallback = onNodesUpdateCallback else { return }
        callback(onNodesUpdateCallback)
    }
    
    func unregisterOnNodesUpdate() -> Void {
        onNodesUpdateCallback = nil
    }
}
