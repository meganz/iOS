public protocol RecentNodesRepositoryProtocol: RepositoryProtocol, Sendable {
    func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity]
}
