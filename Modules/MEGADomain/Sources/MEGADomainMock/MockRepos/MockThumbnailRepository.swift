import Foundation
import MEGADomain

public struct MockThumbnailRepository: ThumbnailRepositoryProtocol {
    private let cachedThumbnailURLs: [(ThumbnailTypeEntity, URL?)]
    private let cachedThumbnailURL: URL
    private let cachedPreviewURL: URL
    private let cachedOriginalURL: URL
    private let loadThumbnailResult: Result<URL, ThumbnailErrorEntity>
    private let loadPreviewResult: Result<URL, ThumbnailErrorEntity>
    
    public init(cachedThumbnailURLs: [(ThumbnailTypeEntity, URL?)] = [],
                cachedThumbnailURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedPreviewURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedOriginalURL: URL = URL(string: "https://MEGA.NZ")!,
                loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)) {
        self.cachedThumbnailURLs = cachedThumbnailURLs
        self.cachedThumbnailURL = cachedThumbnailURL
        self.cachedPreviewURL = cachedPreviewURL
        self.cachedOriginalURL = cachedOriginalURL
        self.loadThumbnailResult = loadThumbnailResult
        self.loadPreviewResult = loadPreviewResult
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL? {
        cachedThumbnailURLs.first {
            $0.0 == type
        }?.1
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        case .original:
            return cachedOriginalURL
        }
    }
    
    public func generateCachingURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        case .original:
            return cachedOriginalURL
        }
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadThumbnail(for: node, type: type) {
                continuation.resume(with: $0)
            }
        }
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        switch type {
        case .thumbnail:
            completion(loadThumbnailResult)
        case .preview, .original:
            completion(loadPreviewResult)
        }
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        nil
    }
}
