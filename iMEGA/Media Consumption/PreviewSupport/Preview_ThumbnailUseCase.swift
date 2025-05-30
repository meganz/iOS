import Foundation
import MEGADomain
import MEGASwift

struct Preview_ThumbnailUseCase: ThumbnailUseCaseProtocol {
    private let url = URL(string: "any-url.com")!
    private let nullThumbnailEntity = ThumbnailEntity(url: URL(string: "any-url.com")!, type: .thumbnail)
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        nil
    }
    
    func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> ThumbnailEntity? {
        nil
    }
    
    func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        URL(string: "any-url.com")!
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        nullThumbnailEntity
    }
    
    func loadThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) async throws -> ThumbnailEntity {
        nullThumbnailEntity
    }
    
    func requestPreview(for node: NodeEntity) -> AnyAsyncThrowingSequence<ThumbnailEntity, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: ThumbnailEntity.self,
            throwing: (any Error).self,
            bufferingPolicy: .unbounded
        )
        continuation.yield(nullThumbnailEntity)
        continuation.finish()
        return stream.eraseToAnyAsyncThrowingSequence()
    }
    
    func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        nil
    }
}
