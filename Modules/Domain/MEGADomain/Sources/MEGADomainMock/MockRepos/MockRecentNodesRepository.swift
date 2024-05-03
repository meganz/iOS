import MEGADomain

public struct MockRecentNodesRepository: RecentNodesRepositoryProtocol {
    public static var newRepo: MockRecentNodesRepository {
        MockRecentNodesRepository()
    }
    
    private let requestResult: Result<Void, GenericErrorEntity>
    
    private let allRecentActionBucketList: [RecentActionBucketEntity]
    
    public init(
        allRecentActionBucketList: [RecentActionBucketEntity] = [],
        requestResult: Result<Void, GenericErrorEntity> = .failure(GenericErrorEntity())
    ) {
        self.allRecentActionBucketList = allRecentActionBucketList
        self.requestResult = requestResult
    }
    
    public func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity] {
        switch requestResult {
        case .success: Array(allRecentActionBucketList.prefix(limitCount))
        case .failure(let error): throw error
        }
    }
}
