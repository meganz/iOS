import Foundation
import Combine
import MEGASwift

// MARK: - Use case protocol -
public protocol ThumbnailUseCaseProtocol {
    
    /// Get the cacheced thumbnail
    /// - Parameters:
    ///   - node: The node to be checked
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: The cached URL if a thumbnail is cached, otherwise it returns nil
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity?
    
    /// Generate caching URL for a thumbnail
    /// - Parameters:
    ///   - node: The node to be checked
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: The caching URL to cache a thumbnail
    func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL
    
    /// Load thumbnail asynchronously with Swift Concurrency
    /// - Parameters:
    ///   - node: The node entity for which the thumbnail to be loaded
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: The url of the cached thumbnail in thumbnail repository
    /// - Throws: `ThumbnailErrorEntity` error
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity
    
    /// Load thumbnail asynchronously with Combine
    /// - Parameters:
    ///   - node: The node entity for which the thumbnail to be loaded
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: A `Future` publisher of the url of the cached thumbnail in thumbnail repository. Or it fails with `ThumbnailErrorEntity` error.
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<ThumbnailEntity, ThumbnailErrorEntity>
    
    /// Request high quality preview of a node. It will publish values multiple times until the high quality preview URL is published.
    /// For example, it may publish this value flow: "thumbnail URL" -> "Preview URL"
    /// - Parameter node: The node entity for which the preview to be loaded
    /// - Returns: A publisher to publish preview URL, and it will publish any low quality thumbnail URL first if they are available
    func requestPreview(for node: NodeEntity) -> AnyPublisher<ThumbnailEntity, ThumbnailErrorEntity>
    
    /// Request thumbnail and preview of a node. It will publish values multiple times until both thumbnail and preview are loaded.
    /// For example, it may publish this value flow: "(nil, nil)" -> "(thumbnail URL, nil)" -> "(thumbnail URL, Preview URL)".
    /// - Parameter node: The node entity for which the thumbnail and preview to be loaded
    /// - Returns: A publisher to publish thumbnail and preview URL values
    func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(ThumbnailEntity?, ThumbnailEntity?), ThumbnailErrorEntity>
    
    /// Find cached preview or original in thumbnail repository
    /// - Parameters:
    ///   - node: The node to be checked
    /// - Returns: The path of the cached preview or original in thumbnail repository
    func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String?
}

public struct ThumbnailUseCase<T: ThumbnailRepositoryProtocol>: ThumbnailUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        repository
            .cachedThumbnail(for: node, type: type)
            .map {
                ThumbnailEntity(url: $0, type: type)
            }
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        repository.generateCachingURL(for: node, type: type)
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        try Task.checkCancellation()
        return try await ThumbnailEntity(url: repository.loadThumbnail(for: node, type: type),
                                         type: type)
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<ThumbnailEntity, ThumbnailErrorEntity> {
        Future { promise in
            repository.loadThumbnail(for: node, type: type) { result in
                promise(result.map { url in ThumbnailEntity(url: url, type: type) })
            }
        }
    }
    
    public func requestPreview(for node: NodeEntity) -> AnyPublisher<ThumbnailEntity, ThumbnailErrorEntity> {
        requestThumbnailAndPreview(for: node)
            .combinePrevious((nil, nil))
            .filter { result in
                result.previous.1 == nil
            }
            .compactMap { result -> ThumbnailEntity? in
                if let preview = result.current.1 {
                    return preview
                } else {
                    return result.current.0
                }
            }
            .eraseToAnyPublisher()
    }
    
    public func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(ThumbnailEntity?, ThumbnailEntity?), ThumbnailErrorEntity> {
        loadThumbnail(for: node, type: .thumbnail)
            .map(Optional.some)
            .prepend(nil)
            .combineLatest(
                loadThumbnail(for: node, type: .preview)
                    .map(Optional.some)
                    .prepend(nil)
            )
            .eraseToAnyPublisher()
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        repository.cachedPreviewOrOriginalPath(for: node)
    }
}
