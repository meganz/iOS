import MEGADomain

public struct MockRecentNodesUseCase: RecentNodesUseCaseProtocol {
    
    public init() { }
    
    public func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity] {
        []
    }
}
