import MEGADomain
import MEGASdk

public final class RecentlyOpenedNodesRepository: RecentlyOpenedNodesRepositoryProtocol {
    
    private let store: any RecentlyOpenedNodesMEGAStoreProtocol
    private let sdk: MEGASdk
    
    public init(
        store: some RecentlyOpenedNodesMEGAStoreProtocol,
        sdk: MEGASdk
    ) {
        self.store = store
        self.sdk = sdk
    }
    
    // MARK: - loadNodes
    
    public func loadNodes() async throws -> [RecentlyOpenedNodeEntity] {
        try await store.fetchRecentlyOpenedNodes()
            .toRecentlyOpenedNodeEntities(using: sdk)
    }
    
    // MARK: - clearNodes
    
    public func clearNodes() async throws {
        try await store.clearRecentlyOpenedNodes()
    }
    
    // MARK: - saveNode
    
    public func saveNode(recentlyOpenedNode: RecentlyOpenedNodeEntity) throws {
        guard let fingerprint = recentlyOpenedNode.node.fingerprint else {
            throw RecentlyOpenedNodesErrorEntity.couldNotSaveNodeFailToGetDataToSave
        }
        store.insertOrUpdateMediaDestination(
            fingerprint: fingerprint,
            destination: recentlyOpenedNode.mediaDestination.destination,
            timescale: recentlyOpenedNode.mediaDestination.timescale
        )
    }
}
