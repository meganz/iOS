import Combine
import Foundation
import MEGADomain

public struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    let hasCachedThumbnail: Bool
    let hasCachedPreview: Bool
    let cachedThumbnailURL: URL
    let cachedPreviewURL: URL
    let loadThumbnailResult: Result<URL, ThumbnailErrorEntity>
    let loadPreviewResult: Result<URL, ThumbnailErrorEntity>
    let loadThumbnailAndPreviewResult: Result<(URL?, URL?), ThumbnailErrorEntity>
    
    public init(hasCachedThumbnail: Bool = false,
                hasCachedPreview: Bool = false,
                cachedThumbnailURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedPreviewURL: URL = URL(string: "https://MEGA.NZ")!,
                loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadThumbnailAndPreviewResult: Result<(URL?, URL?), ThumbnailErrorEntity> = .failure(.generic)) {
        self.hasCachedThumbnail = hasCachedThumbnail
        self.hasCachedPreview = hasCachedPreview
        self.cachedThumbnailURL = cachedThumbnailURL
        self.cachedPreviewURL = cachedPreviewURL
        self.loadThumbnailResult = loadThumbnailResult
        self.loadPreviewResult = loadPreviewResult
        self.loadThumbnailAndPreviewResult = loadThumbnailAndPreviewResult
    }
    
    public func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        switch type {
        case .thumbnail:
            return hasCachedThumbnail
        case .preview:
            return hasCachedPreview
        }
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        }
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            switch type {
            case .thumbnail:
                continuation.resume(with: loadThumbnailResult)
            case .preview:
                continuation.resume(with: loadPreviewResult)
            }
        }
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            switch type {
            case .thumbnail:
                promise(loadThumbnailResult)
            case .preview:
                promise(loadPreviewResult)
            }
        }
    }
    
    public func requestPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity> {
        loadPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    public func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
}
