public protocol RecentNodesUseCaseProtocol: Sendable {
    func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity]
}

public struct RecentNodesUseCase<T: RecentNodesRepositoryProtocol>: RecentNodesUseCaseProtocol {
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    public func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity] {
        try await repo.recentActionBuckets(limitCount: limitCount)
    }
}
