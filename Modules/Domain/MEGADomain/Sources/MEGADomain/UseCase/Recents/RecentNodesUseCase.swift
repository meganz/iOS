public protocol RecentNodesUseCaseProtocol: Sendable {
    
    /// Fetch a list of recent action buckets. The fetched results will filter sensitive nodes based on users preference setting.
    /// - Parameter limitCount: Maximum number of nodes to return
    /// - Returns: List of RecentActionBucketEntity
    func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity]
    
    /// Fetch a list of recent action buckets. The fetched results will filter sensitive nodes based on the provided excludeSensitive param
    /// - Parameter limitCount: Maximum number of nodes to return
    /// - Parameter excludeSensitive: Determines if sensitive nodes should be excluded from final result.
    /// - Returns: List of RecentActionBucketEntity
    func recentActionBuckets(limitCount: Int, excludeSensitive: Bool) async throws -> [RecentActionBucketEntity]
}

public struct RecentNodesUseCase<T: RecentNodesRepositoryProtocol, S: ContentConsumptionUserAttributeUseCaseProtocol>: RecentNodesUseCaseProtocol {
    private let recentNodesRepository: T
    private let contentConsumptionUserAttributeUseCase: S
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool

    public init(recentNodesRepository: T,
                contentConsumptionUserAttributeUseCase: S,
                hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool) {
        self.recentNodesRepository = recentNodesRepository
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
    }
    
    public func recentActionBuckets(limitCount: Int) async throws -> [RecentActionBucketEntity] {
        try await fetchRecentActionBuckets(limitCount: limitCount, excludeSensitive: nil)
    }

    public func recentActionBuckets(limitCount: Int, excludeSensitive: Bool) async throws -> [RecentActionBucketEntity] {
        try await fetchRecentActionBuckets(limitCount: limitCount, excludeSensitive: excludeSensitive)
    }
        
    private func fetchRecentActionBuckets(limitCount: Int, excludeSensitive: Bool?) async throws -> [RecentActionBucketEntity] {
        let shouldExcludeSensitive = await shouldExcludeSensitive(override: excludeSensitive)
        return try await recentNodesRepository.recentActionBuckets(
            limitCount: limitCount,
            excludeSensitive: shouldExcludeSensitive)
    }
    
    private func shouldExcludeSensitive(override: Bool?) async -> Bool {
        guard hiddenNodesFeatureFlagEnabled() else {
            return false
        }
        
        guard let override else {
            return await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        }
        return override
    }
}
