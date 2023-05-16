public protocol RecentNodesRepositoryProtocol: RepositoryProtocol {
    func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity]
}
