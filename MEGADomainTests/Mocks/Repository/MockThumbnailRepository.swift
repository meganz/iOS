import Foundation
@testable import MEGA
import MEGADomain

struct MockThumbnailRepository: ThumbnailRepositoryProtocol {
    var cachedThumbnailURLs = [(ThumbnailTypeEntity, URL?)]()
    var cachedThumbnailURL = URL(string: "https://MEGA.NZ")!
    var cachedPreviewURL = URL(string: "https://MEGA.NZ")!
    var cachedOriginalURL = URL(string: "https://MEGA.NZ")!
    var loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)
    var loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL? {
        cachedThumbnailURLs.first {
            $0.0 == type
        }?.1
    }
    
    func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        case .original:
            return cachedOriginalURL
        }
    }
    
    func generateCachingURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        case .original:
            return cachedOriginalURL
        }
    }

    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadThumbnail(for: node, type: type) {
                continuation.resume(with: $0)
            }
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        switch type {
        case .thumbnail:
            completion(loadThumbnailResult)
        case .preview, .original:
            completion(loadPreviewResult)
        }
    }
    
    func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        nil
    }
}
