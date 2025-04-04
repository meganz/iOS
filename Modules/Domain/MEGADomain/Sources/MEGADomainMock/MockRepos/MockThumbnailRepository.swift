import Foundation
import MEGADomain

public struct MockThumbnailRepository: ThumbnailRepositoryProtocol {
    public static let newRepo = MockThumbnailRepository()
    
    private let cachedThumbnailURLs: [(ThumbnailTypeEntity, URL?)]
    private let cachedThumbnailURL: URL
    private let cachedPreviewURL: URL
    private let cachedOriginalURL: URL
    private let loadThumbnailResult: Result<URL, any Error>
    private let loadPreviewResult: Result<URL, any Error>
    
    public init(cachedThumbnailURLs: [(ThumbnailTypeEntity, URL?)] = [],
                cachedThumbnailURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedPreviewURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedOriginalURL: URL = URL(string: "https://MEGA.NZ")!,
                loadThumbnailResult: Result<URL, any Error> = .failure(GenericErrorEntity()),
                loadPreviewResult: Result<URL, any Error> = .failure(GenericErrorEntity())) {
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
            switch type {
            case .thumbnail:
                continuation.resume(with: loadThumbnailResult)
            case .preview, .original:
                continuation.resume(with: loadPreviewResult)
            }
        }
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        nil
    }
}
