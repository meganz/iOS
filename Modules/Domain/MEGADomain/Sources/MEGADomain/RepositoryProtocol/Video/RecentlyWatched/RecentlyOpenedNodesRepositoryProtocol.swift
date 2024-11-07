public protocol RecentlyOpenedNodesRepositoryProtocol: Sendable {
    
    /// Load recently opened nodes represented as colletion of `RecentlyOpenedNodeEntity` object.
    /// - Returns: an array of `RecentlyOpenedNodeEntity`.
    func loadNodes() async throws -> [RecentlyOpenedNodeEntity]
    
    /// Clear all recently opened nodes.
    ///  - Throws: Throws error if clear found error.
    func clearNodes() async throws
    
    /// Save currently opened node  using `RecentlyOpenedNodeEntity` representation.
    /// - Parameter recentlyOpenedNode: an object representing videos that is currently watched. The object contains the `nodeEntity`, `lastOpenedDate`, and `mediaDestination`.
    /// - Throws: throws error if failed to save opened node,
    func saveNode(recentlyOpenedNode: RecentlyOpenedNodeEntity) throws
    
    /// Clear node for specific fingerprint
    /// - Parameter fingerprint: node fingerprint
    /// - Throws:`RecentlyOpenedNodesErrorEntity` as error representation type
    func clearNode(for fingerprint: String) async throws(RecentlyOpenedNodesErrorEntity)
}
