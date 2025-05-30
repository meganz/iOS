import Combine
import Foundation
import MEGASwift

// MARK: - Use case protocol -
public protocol ThumbnailUseCaseProtocol: Sendable {
    
    /// Get the cacheced thumbnail
    /// - Parameters:
    ///   - node: The node to be checked
    ///   - type: `ThumbnailTypeEntity` thumbnail type
    /// - Returns: The cached URL if a thumbnail is cached, otherwise it returns nil
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity?
    
    func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity?
    
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
    /// - Throws: `ThumbnailErrorEntity` or `GenericErrorEntity` error.
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity
        
    func loadThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity
    
    /// Request high quality preview of a node. It will publish values multiple times until the high quality preview URL is published.
    /// For example, it may publish this value flow: "thumbnail URL" -> "Preview URL"
    /// - Parameter node: The node entity for which the preview to be loaded
    /// - Returns: An AsyncSequence to publish preview URL, and it will publish any low quality thumbnail URL first if they are available
    func requestPreview(for node: NodeEntity) -> AnyAsyncThrowingSequence<ThumbnailEntity, any Error>
        
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
        
    public func requestPreview(for node: NodeEntity) -> AnyAsyncThrowingSequence<ThumbnailEntity, any Error> {
        let (stream, continuation) = AsyncThrowingStream
            .makeStream(of: ThumbnailEntity.self, throwing: (any Error).self, bufferingPolicy: .bufferingNewest(1))
        
        let task = Task {
            try await withThrowingTaskGroup(of: ThumbnailEntity.self) { group in
                
                [ThumbnailTypeEntity.thumbnail, .preview]
                    .forEach { type in
                        _ = group.addTaskUnlessCancelled { try await loadThumbnail(for: node, type: type) }
                    }
                try Task.checkCancellation()
                
                while let results = await group.nextResult() {
                    try Task.checkCancellation()
                    switch results {
                    case .success(let thumbnail):
                        continuation.yield(thumbnail)
                        if thumbnail.type == .preview {
                            group.cancelAll()
                            continuation.finish()
                            break
                        }
                    case .failure:
                        break
                    }
                }
                
                try Task.checkCancellation()
                
                continuation.finish(throwing: ThumbnailErrorEntity.noThumbnails)
            }
        }
        
        continuation.onTermination = { @Sendable _ in task.cancel() }
        
        return stream.eraseToAnyAsyncThrowingSequence()
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        repository.cachedPreviewOrOriginalPath(for: node)
    }
    
    public func loadThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        try Task.checkCancellation()
        return try await ThumbnailEntity(
            url: repository.loadThumbnail(for: nodeHandle, type: type),
            type: type
        )
    }
    
    public func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        repository
            .cachedThumbnail(for: nodeHandle, type: type)
            .map {
                ThumbnailEntity(url: $0, type: type)
            }
    }
}
