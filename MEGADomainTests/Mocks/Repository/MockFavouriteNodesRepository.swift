import XCTest
@testable import MEGA
import MEGADomain

final class MockFavouriteNodesRepository: FavouriteNodesRepositoryProtocol {
    
    static var newRepo: MockFavouriteNodesRepository = MockFavouriteNodesRepository(result: .success([])) 
    
    private var result: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    
    init(result: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .success([])) {
        self.result = result
    }
    
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(result)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(result)
    }
    
    func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(result)
    }
    
    func allFavouritesNodes() async throws -> [NodeEntity] {
        [NodeEntity]()
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) { }
    
    func unregisterOnNodesUpdate() {}

}
