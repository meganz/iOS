import MEGADomain

public final class MockFavouriteNodesRepository: FavouriteNodesRepositoryProtocol {
    
    public static let newRepo: MockFavouriteNodesRepository = MockFavouriteNodesRepository(result: .success([]))
    
    private let result: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    
    public init(result: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .success([])) {
        self.result = result
    }
        
    public func allFavouritesNodes(searchString: String?, limit: Int) async throws -> [NodeEntity] {
        try result.get()
    }
    
    public func allFavouritesNodes(limit: Int) async throws -> [NodeEntity] {
        try result.get()
    }
}
