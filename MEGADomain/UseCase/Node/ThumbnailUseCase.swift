import Foundation
import Combine

// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    
    /// Get the thumbnail placeholder file type for a node file
    /// - Parameter name: The name of the node file
    /// - Returns: A `MEGAFileType`
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType
    
    /// Check if there is cached thumbnail in thumbnail repository
    /// - Parameters:
    ///   - node: The node to be checked
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: If a thumbnail is cached or not
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool
    
    /// Find cached thumbnail in thumbnail repository
    /// - Parameters:
    ///   - node: The node to be checked
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: The url of the cached thumbnail in thumbnail repository
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL
    
    /// Load thumbnail asynchronously with Swift Concurrency
    /// - Parameters:
    ///   - node: The node entity for which the thumbnail to be loaded
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: The url of the cached thumbnail in thumbnail repository
    /// - Throws: `ThumbnailErrorEntity` error
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL
    
    /// Load thumbnail asynchronously with Combine
    /// - Parameters:
    ///   - node: The node entity for which the thumbnail to be loaded
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: A `Future` publisher of the url of the cached thumbnail in thumbnail repository. Or it fails with `ThumbnailErrorEntity` error.
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity>
    
    
    /// Request high quality preview of a node. It will publish values multiple times until the high quality preview URL is published.
    /// For example, it may publish this value flow: "thumbnail URL" -> "Preview URL"
    /// - Parameter node: The node entity for which the preview to be loaded
    /// - Returns: A publisher to publish preview URL, and it will publish any low quality thumbnail URL first if they are available
    func requestPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity>
    
    
    /// Request thumbnail and preview of a node. It will publish values multiple times until both thumbnail and preview are loaded.
    /// For example, it may publish this value flow: "(nil, nil)" -> "(thumbnail URL, nil)" -> "(thumbnail URL, Preview URL)".
    /// - Parameter node: The node entity for which the thumbnail and preview to be loaded
    /// - Returns: A publisher to publish thumbnail and preview URL values
    func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity>
}

struct ThumbnailUseCase<T: ThumbnailRepositoryProtocol>: ThumbnailUseCaseProtocol {
    private let repository: T
    private let fileTypes = FileTypes()
    
    init(repository: T) {
        self.repository = repository
    }
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType {
        fileTypes.fileType(forFileName: name)
    }
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        repository.hasCachedThumbnail(for: node, type: type)
    }
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        repository.cachedThumbnail(for: node, type: type)
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try Task.checkCancellation()
        return try await repository.loadThumbnail(for: node, type: type)
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            repository.loadThumbnail(for: node, type: type, completion: promise)
        }
    }
    
    func requestPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity> {
        requestThumbnailAndPreview(for: node)
            .combinePrevious((nil, nil))
            .filter { result in
                result.previous.1 == nil
            }
            .compactMap { result -> URL? in
                if let previewURL = result.current.1 {
                    return previewURL
                } else {
                    return result.current.0
                }
            }
            .eraseToAnyPublisher()
    }
    
    func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
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
}

extension ThumbnailUseCase where T == ThumbnailRepository {
    static let `default` = ThumbnailUseCase(repository: T.default)
}
