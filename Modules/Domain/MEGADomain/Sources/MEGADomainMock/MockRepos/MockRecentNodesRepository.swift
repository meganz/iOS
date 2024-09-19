import MEGADomain
import MEGASwift

public struct MockRecentNodesRepository: RecentNodesRepositoryProtocol {
    
    public static var newRepo: MockRecentNodesRepository {
        MockRecentNodesRepository()
    }
    
    private let requestResult: Result<Void, GenericErrorEntity>
    
    private let allRecentActionBucketList: [RecentActionBucketEntity]
    
    public enum Invocation: Sendable, Equatable {
        case recentActionBuckets(limit: Int, excludeSensitive: Bool)
    }
    
    @Atomic public var invocations: [Invocation] = []

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
    
    public func recentActionBuckets(limitCount: Int, excludeSensitive: Bool) async throws -> [RecentActionBucketEntity] {
        $invocations.mutate {
            $0.append(.recentActionBuckets(limit: limitCount, excludeSensitive: excludeSensitive))
        }
        return switch requestResult {
        case .success: Array(allRecentActionBucketList.prefix(limitCount))
        case .failure(let error): throw error
        }
    }
}
