import MEGADomain
import MEGASwift

public struct MockRecentNodesUseCase: RecentNodesUseCaseProtocol {
    
    public enum Invocation: Sendable, Equatable {
        case recentActionBucketsWithOutExclude(limit: Int)
        case recentActionBuckets(limit: Int, excludeSensitive: Bool)
    }
    
    @Atomic public var invocations: [Invocation] = []
    
    private let recentActionBuckets: Result<[RecentActionBucketEntity], GenericErrorEntity>
    
    public init(
        recentActionBuckets: Result<[RecentActionBucketEntity], GenericErrorEntity> = .success([])
    ) {
        self.recentActionBuckets = recentActionBuckets
    }
    
    public func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity] {
        $invocations.mutate { $0.append(.recentActionBucketsWithOutExclude(limit: limitCount))}
        return try recentActionBuckets.get()
    }
    
    public func recentActionBuckets(limitCount: Int, excludeSensitive: Bool) async throws -> [RecentActionBucketEntity] {
        $invocations.mutate { $0.append(.recentActionBuckets(limit: limitCount, excludeSensitive: excludeSensitive))}
        return try recentActionBuckets.get()
    }
}
