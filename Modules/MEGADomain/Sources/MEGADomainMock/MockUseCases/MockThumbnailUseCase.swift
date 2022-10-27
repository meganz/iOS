import Combine
import Foundation
import MEGADomain

public struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    private let hasCachedThumbnail: Bool
    private let hasCachedPreview: Bool
    private let hasCachedOriginal: Bool
    private let cachedThumbnailURL: URL
    private let cachedPreviewURL: URL
    private let cachedOriginalURL: URL
    private let loadThumbnailResult: Result<URL, ThumbnailErrorEntity>
    private let loadPreviewResult: Result<URL, ThumbnailErrorEntity>
    private let loadThumbnailAndPreviewResult: Result<(URL?, URL?), ThumbnailErrorEntity>
    
    public init(hasCachedThumbnail: Bool = false,
                hasCachedPreview: Bool = false,
                hasCachedOriginal: Bool = false,
                cachedThumbnailURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedPreviewURL: URL = URL(string: "https://MEGA.NZ")!,
                cachedOriginalURL: URL = URL(string: "https://MEGA.NZ")!,
                loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic),
                loadThumbnailAndPreviewResult: Result<(URL?, URL?), ThumbnailErrorEntity> = .failure(.generic)) {
        self.hasCachedThumbnail = hasCachedThumbnail
        self.hasCachedPreview = hasCachedPreview
        self.hasCachedOriginal = hasCachedOriginal
        self.cachedThumbnailURL = cachedThumbnailURL
        self.cachedPreviewURL = cachedPreviewURL
        self.cachedOriginalURL = cachedOriginalURL
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
        case .original:
            return hasCachedOriginal
        }
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
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
        loadPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    public func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        cachedPreviewURL.absoluteString
    }
}
