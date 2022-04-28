protocol ThumbnailRepositoryProtocol {
    func hasCachedThumbnail(for node: NodeEntity) -> Bool
    func hasCachedPreview(for node: NodeEntity) -> Bool
    func cachedThumbnail(for node: NodeEntity) -> URL
    func cachedPreview(for node: NodeEntity) -> URL
    
    /// Load thumbnail for node
    /// - Parameter node: node
    /// - Returns: location of resource
    /// - Throws: ThumbnailErrorEntity, such as .generil, .noThumbnail(.thumbnail), nodeNotFound
    func loadThumbnail(for node: NodeEntity) async throws -> URL
    
    
    /// Load preview for node
    /// - Parameter node: node
    /// - Returns: location of resource
    /// - Throws: ThumbnailErrorEntity, such as .generil, .noThumbnail(.preview), nodeNotFound
    func loadPreview(for node: NodeEntity) async throws -> URL
}
