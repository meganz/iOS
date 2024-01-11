import Combine
import Foundation
import MEGADomain
import MEGASwift

public struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
        
    let cachedThumbnails: [ThumbnailEntity]
    let generatedCachingThumbnail: ThumbnailEntity
    let loadThumbnailResult: Result<ThumbnailEntity, Error>
    let loadPreviewResult: Result<ThumbnailEntity, Error>
    let loadThumbnailAndPreviewResult: Result<(ThumbnailEntity?, ThumbnailEntity?), Error>
    
    public init(cachedThumbnails: [ThumbnailEntity] = [],
                generatedCachingThumbnail: ThumbnailEntity = ThumbnailEntity(url: URL(string: "https://MEGA.NZ")!, type: .thumbnail),
                loadThumbnailResult: Result<ThumbnailEntity, Error> = .failure(GenericErrorEntity()),
                loadPreviewResult: Result<ThumbnailEntity, Error> = .failure(GenericErrorEntity()),
                loadThumbnailAndPreviewResult: Result<(ThumbnailEntity?, ThumbnailEntity?), Error> = .failure(GenericErrorEntity())) {
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
    
    public func requestPreview(for node: MEGADomain.NodeEntity) -> AnyAsyncThrowingSequence<MEGADomain.ThumbnailEntity, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: ThumbnailEntity.self, throwing: Error.self, bufferingPolicy: .unbounded)

        if case .success = loadThumbnailResult, case .success = loadPreviewResult {
            continuation.yield(with: loadThumbnailResult)
            continuation.yield(with: loadPreviewResult)
        } else if case .success = loadThumbnailResult {
            continuation.yield(with: loadThumbnailResult)
        } else {
            continuation.yield(with: loadPreviewResult)
        }
        continuation.finish()
        return stream.eraseToAnyAsyncThrowingSequence()
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        generatedCachingThumbnail.url.absoluteString
    }
}
