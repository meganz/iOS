import Combine
import Foundation
import MEGADomain

public struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    let cachedThumbnailURLs: [(ThumbnailTypeEntity, URL?)]
    let generatedThumbnailCachingURL: URL
    let generatedPreviewCachingURL: URL
    let generatedOriginalCachingURL: URL
    let loadThumbnailResult: Result<URL, ThumbnailErrorEntity>
    let loadPreviewResult: Result<URL, ThumbnailErrorEntity>
    let loadThumbnailAndPreviewResult: Result<(URL?, URL?), ThumbnailErrorEntity>
    
    public init(cachedThumbnailURLs: [(ThumbnailTypeEntity, URL?)] = [],
                generatedThumbnailCachingURL: URL = URL(string: "https://MEGA.NZ")!,
                generatedPreviewCachingURL: URL = URL(string: "https://MEGA.NZ")!,
                generatedOriginalCachingURL: URL = URL(string: "https://MEGA.NZ")!,
                loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadThumbnailAndPreviewResult: Result<(URL?, URL?), ThumbnailErrorEntity> = .failure(.generic)) {
        self.cachedThumbnailURLs = cachedThumbnailURLs
        self.generatedThumbnailCachingURL = generatedThumbnailCachingURL
        self.generatedPreviewCachingURL = generatedPreviewCachingURL
        self.generatedOriginalCachingURL = generatedOriginalCachingURL
        self.loadThumbnailResult = loadThumbnailResult
        self.loadPreviewResult = loadPreviewResult
        self.loadThumbnailAndPreviewResult = loadThumbnailAndPreviewResult
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL? {
        cachedThumbnailURLs.first {
            $0.0 == type
        }?.1
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return generatedThumbnailCachingURL
        case .preview:
            return generatedPreviewCachingURL
        case .original:
            return generatedOriginalCachingURL
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
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            switch type {
            case .thumbnail:
                promise(loadThumbnailResult)
            case .preview, .original:
                promise(loadPreviewResult)
            }
        }
    }
    
    public func requestPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity> {
        if case .success = loadThumbnailResult, case .success = loadPreviewResult {
            return loadThumbnailResult
                .publisher
                .append(loadPreviewResult.publisher)
                .eraseToAnyPublisher()
        } else if case .success = loadThumbnailResult {
            return loadThumbnailResult.publisher.eraseToAnyPublisher()
        } else {
            return loadPreviewResult.publisher.eraseToAnyPublisher()
        }
    }
    
    public func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        generatedPreviewCachingURL.absoluteString
    }
}
