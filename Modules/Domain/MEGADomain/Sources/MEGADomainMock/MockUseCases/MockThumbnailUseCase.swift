import Combine
import Foundation
import MEGADomain

public struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    let cachedThumbnails: [ThumbnailEntity]
    let generatedCachingThumbnail: ThumbnailEntity
    let loadThumbnailResult: Result<ThumbnailEntity, ThumbnailErrorEntity>
    let loadPreviewResult: Result<ThumbnailEntity, ThumbnailErrorEntity>
    let loadThumbnailAndPreviewResult: Result<(ThumbnailEntity?, ThumbnailEntity?), ThumbnailErrorEntity>
    
    public init(cachedThumbnails: [ThumbnailEntity] = [],
                generatedCachingThumbnail: ThumbnailEntity = ThumbnailEntity(url: URL(string: "https://MEGA.NZ")!, type: .thumbnail),
                loadThumbnailResult: Result<ThumbnailEntity, ThumbnailErrorEntity> = .failure(.generic),
                loadPreviewResult: Result<ThumbnailEntity, ThumbnailErrorEntity> = .failure(.generic),
                loadThumbnailAndPreviewResult: Result<(ThumbnailEntity?, ThumbnailEntity?), ThumbnailErrorEntity> = .failure(.generic)) {
        self.cachedThumbnails = cachedThumbnails
        self.generatedCachingThumbnail = generatedCachingThumbnail
        self.loadThumbnailResult = loadThumbnailResult
        self.loadPreviewResult = loadPreviewResult
        self.loadThumbnailAndPreviewResult = loadThumbnailAndPreviewResult
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        cachedThumbnails.first { $0.type == type }
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        generatedCachingThumbnail.url
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        try await withCheckedThrowingContinuation { continuation in
            switch type {
            case .thumbnail:
                continuation.resume(with: loadThumbnailResult)
            case .preview, .original:
                continuation.resume(with: loadPreviewResult)
            }
        }
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<ThumbnailEntity, ThumbnailErrorEntity> {
        Future { promise in
            switch type {
            case .thumbnail:
                promise(loadThumbnailResult)
            case .preview, .original:
                promise(loadPreviewResult)
            }
        }
    }
    
    public func requestPreview(for node: NodeEntity) -> AnyPublisher<ThumbnailEntity, ThumbnailErrorEntity> {
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
    
    public func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(ThumbnailEntity?, ThumbnailEntity?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        generatedCachingThumbnail.url.absoluteString
    }
}
