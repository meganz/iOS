import MEGADomain

public final class MockFavouriteNodesRepository: FavouriteNodesRepositoryProtocol {
    
    public static var newRepo: MockFavouriteNodesRepository = MockFavouriteNodesRepository(result: .success([]))
    
    private let result: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    
    public init(result: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .success([])) {
        self.result = result
    }
    
    public func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(result)
    }
    
    public func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(result)
    }
    
    public func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(result)
    }
    
    public func allFavouritesNodes(searchString: String?, limit: Int) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: result)
        }
    }
    
    public func allFavouritesNodes(limit: Int) async throws -> [NodeEntity] {
        try result.get()
    }
    
    public func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) { }
    
    public func unregisterOnNodesUpdate() {}
}
