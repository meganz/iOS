@testable import MEGA

final class MockFavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    var getAllFavouriteNodesWithSearchResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic)
    var getAllFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic)
    var getFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic)
    var onNodesUpdateCallback: [NodeEntity]? = [NodeEntity()]
   
    func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getAllFavouriteNodesWithSearchResult)
    }
    
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getAllFavouriteNodesResult)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getFavouriteNodesResult)
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        guard let onNodesUpdateCallback = onNodesUpdateCallback else { return }
        callback(onNodesUpdateCallback)
    }
    
    func unregisterOnNodesUpdate() -> Void {
        onNodesUpdateCallback = nil
    }
}
