import AsyncAlgorithms
import MEGASwift

public protocol RecentNodesUseCaseProtocol: Sendable {
    var recentActionBucketsUpdates: AnyAsyncSequence<Void> { get }
    
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

public struct RecentNodesUseCase<T: RecentNodesRepositoryProtocol, S: ContentConsumptionUserAttributeUseCaseProtocol, U: UserUpdateRepositoryProtocol, R: RequestStatesRepositoryProtocol, N: NodeRepositoryProtocol>: RecentNodesUseCaseProtocol {
    private let recentNodesRepository: T
    private let contentConsumptionUserAttributeUseCase: S
    private let userUpdateRepository: U
    private let requestStatesRepository: R
    private let nodeRepository: N
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool

    public var recentActionBucketsUpdates: AnyAsyncSequence<Void> {
        let userUpdates = userUpdateRepository
            .usersUpdates
            .filter { $0.contains(where: { $0.changes.contains(.CCPrefs) }) }
            .map { _ in () }
        
        let requestFinishUpdates = requestStatesRepository
            .requestFinishUpdates
            .compactMap { try? $0.get() }
            .filter { $0.type == .fetchNodes }
            .map { _ in () }
        
        let nodeUpdates = nodeRepository
            .nodeUpdates
            .filter {
                $0.contains { nodeEntity in
                    let isNotFolder = !nodeEntity.isFolder
                    let isNotNewNode = !nodeEntity.changeTypes.contains(.new)
                    let isNotRemoved = !nodeEntity.changeTypes.contains(.removed)
                    return (isNotFolder || isNotNewNode) && isNotRemoved
                }
            }
            .map { _ in () }
        
        return merge(
            userUpdates,
            requestFinishUpdates,
            nodeUpdates
        ).eraseToAnyAsyncSequence()
    }
    
    public init(recentNodesRepository: T,
                contentConsumptionUserAttributeUseCase: S,
                userUpdateRepository: U,
                requestStatesRepository: R,
                nodeRepository: N,
                hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool
    ) {
        self.recentNodesRepository = recentNodesRepository
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.userUpdateRepository = userUpdateRepository
        self.requestStatesRepository = requestStatesRepository
        self.nodeRepository = nodeRepository
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
