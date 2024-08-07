import MEGADomain

public final class MockFavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    private let getAllFavouriteNodesWithSearchResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    private let getAllFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    private let getFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity>
    private var onNodesUpdateCallback: [NodeEntity]?
    
    public init(
        getAllFavouriteNodesWithSearchResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic),
        getAllFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity>  = .failure(.generic),
        getFavouriteNodesResult: Result<[NodeEntity], GetFavouriteNodesErrorEntity> = .failure(.generic),
        onNodesUpdateCallback: [NodeEntity]? = nil
    ) {
        self.getAllFavouriteNodesWithSearchResult = getAllFavouriteNodesWithSearchResult
        self.getAllFavouriteNodesResult = getAllFavouriteNodesResult
        self.getFavouriteNodesResult = getFavouriteNodesResult
        self.onNodesUpdateCallback = onNodesUpdateCallback
    }
    
    public func allFavouriteNodes(searchString: String?) async throws -> [MEGADomain.NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: getAllFavouriteNodesWithSearchResult)
        }
    }
   
    public func allFavouriteNodes(searchString: String?, excludeSensitives: Bool, limit: Int) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: getAllFavouriteNodesWithSearchResult)
        }
    }
    
    public func allFavouriteNodes(searchString: String?, excludeSensitives: Bool) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: getAllFavouriteNodesWithSearchResult)
        }
    }
    
    public func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getAllFavouriteNodesResult)
    }
    
    public func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        completion(getFavouriteNodesResult)
    }
    
    public func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        guard let onNodesUpdateCallback = onNodesUpdateCallback else { return }
        callback(onNodesUpdateCallback)
    }
    
    public func unregisterOnNodesUpdate() {
        onNodesUpdateCallback = nil
    }
}
