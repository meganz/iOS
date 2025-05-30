import Combine
import Foundation
import MEGADomain
import MEGASwift

public struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
        
    let cachedThumbnails: [ThumbnailEntity]
    let generatedCachingThumbnail: ThumbnailEntity
    let loadThumbnailResult: Result<ThumbnailEntity, any Error>
    let loadThumbnailResults: [HandleEntity: Result<ThumbnailEntity, any Error>]
    let loadPreviewResult: Result<ThumbnailEntity, any Error>
    let loadThumbnailAndPreviewResult: Result<(ThumbnailEntity?, ThumbnailEntity?), any Error>
    
    public init(cachedThumbnails: [ThumbnailEntity] = [],
                generatedCachingThumbnail: ThumbnailEntity = ThumbnailEntity(url: URL(string: "https://MEGA.NZ")!, type: .thumbnail),
                loadThumbnailResult: Result<ThumbnailEntity, any Error> = .failure(GenericErrorEntity()),
                loadThumbnailResults: [HandleEntity: Result<ThumbnailEntity, any Error>] = [:],
                loadPreviewResult: Result<ThumbnailEntity, any Error> = .failure(GenericErrorEntity()),
                loadThumbnailAndPreviewResult: Result<(ThumbnailEntity?, ThumbnailEntity?), any Error> = .failure(GenericErrorEntity())) {
        self.cachedThumbnails = cachedThumbnails
        self.generatedCachingThumbnail = generatedCachingThumbnail
        self.loadThumbnailResult = loadThumbnailResult
        self.loadThumbnailResults = loadThumbnailResults
        self.loadPreviewResult = loadPreviewResult
        self.loadThumbnailAndPreviewResult = loadThumbnailAndPreviewResult
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        cachedThumbnails.first { $0.type == type }
    }
    
    public func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        cachedThumbnails.first { $0.type == type }
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        generatedCachingThumbnail.url
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        try await withCheckedThrowingContinuation { continuation in
            switch type {
            case .thumbnail:
                continuation.resume(with: loadThumbnailResult(for: node.handle))
            case .preview, .original:
                continuation.resume(with: loadPreviewResult)
            }
        }
    }
    
    public func loadThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        switch type {
        case .thumbnail:
            try loadThumbnailResult(for: nodeHandle).get()
        case .preview, .original:
            try loadPreviewResult.get()
        }
    }
    
    public func requestPreview(for node: NodeEntity) -> AnyAsyncThrowingSequence<ThumbnailEntity, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: ThumbnailEntity.self, throwing: (any Error).self, bufferingPolicy: .unbounded)
        
        let loadThumbnailResult = loadThumbnailResult(for: node.handle)
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
    
    // MARK: Helper
    private func loadThumbnailResult(for nodeHandle: HandleEntity) -> Result<ThumbnailEntity, any Error> {
        guard let result = loadThumbnailResults.first(where: { $0.key == nodeHandle })?.value else {
            return loadThumbnailResult
        }
        return result
    }
}
