import Foundation

public protocol ThumbnailRepositoryProtocol: RepositoryProtocol, Sendable {
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL?
    func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> URL?
    func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL
    func generateCachingURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL
    
    /// Load thumbnail for a `NodeEntity`
    /// - Parameters:
    ///   - node: The node entity
    ///   - type: The type of the thumbnail
    /// - Returns: The URL of the loaded thumbnail
    /// - Throws: An error of `ThumbnailErrorEntity` or `GenericErrorEntity`
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL
    
    func loadThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) async throws -> URL
    
    func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String?
}
