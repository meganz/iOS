import MEGADomain

public final class MockFavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    private let getAllFavouriteNodesWithSearchResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    
    public init(
        getAllFavouriteNodesWithSearchResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic)
    ) {
        self.getAllFavouriteNodesWithSearchResult = getAllFavouriteNodesWithSearchResult
    }
    
    public func allFavouriteNodes(searchString: String?) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: getAllFavouriteNodesWithSearchResult)
        }
    }
   
    public func allFavouriteNodes(searchString: String?, excludeSensitives: Bool, limit: Int) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: getAllFavouriteNodesWithSearchResult)
        }
    }
}
