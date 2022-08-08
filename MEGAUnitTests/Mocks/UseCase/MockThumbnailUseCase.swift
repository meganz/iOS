@testable import MEGA
import Combine
import MEGADomain

struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    var placeholderFileType: MEGAFileType = "generic"
    var hasCachedThumbnail = false
    var hasCachedPreview = false
    var cachedThumbnailURL = URL(string: "https://MEGA.NZ")!
    var cachedPreviewURL = URL(string: "https://MEGA.NZ")!
    var loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)
    var loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)
    var loadThumbnailAndPreviewResult: (Result<(URL?, URL?), ThumbnailErrorEntity>) = .failure(.generic)
    
    func thumbnailPlaceholderFileType(forNodeName: String) -> MEGAFileType {
        placeholderFileType
    }
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        switch type {
        case .thumbnail:
            return hasCachedThumbnail
        case .preview:
            return hasCachedPreview
        }
    }
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            switch type {
            case .thumbnail:
                continuation.resume(with: loadThumbnailResult)
            case .preview:
                continuation.resume(with: loadPreviewResult)
            }
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            switch type {
            case .thumbnail:
                promise(loadThumbnailResult)
            case .preview:
                promise(loadPreviewResult)
            }
        }
    }
    
    func requestPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity> {
        loadPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    func requestThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
}
