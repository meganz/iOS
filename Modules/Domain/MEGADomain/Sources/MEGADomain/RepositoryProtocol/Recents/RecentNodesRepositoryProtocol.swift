public protocol RecentNodesRepositoryProtocol: RepositoryProtocol, Sendable {
    
    /// Fetch a list of recent action buckets. The fetched results will filter sensitive nodes based on the provided excludeSensitive param
    /// - Parameter limitCount: Maximum number of nodes to return
    /// - Parameter excludeSensitive: Determines if sensitive nodes should be excluded from final result.
    /// - Returns: List of RecentActionBucketEntity
    func recentActionBuckets(limitCount: Int, excludeSensitive: Bool) async throws -> [RecentActionBucketEntity]
}
