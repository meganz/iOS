@testable import MEGA
import Combine

struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    var loadThumbnailResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var loadPreviewResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var loadThumbnailAndPreviewResult: (Result<(URL?, URL?), ThumbnailErrorEntity>) = .failure(.generic)
    var loadPrevieResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var placeholderFileType: MEGAFileType = "generic"
    var hasCachedThumbnail = false
    var hasCachedPreview = false
    var cachedThumbnail = URL(string: "https://MEGA.NZ")!
    var cachedPreview = URL(string: "https://MEGA.NZ")!
    
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
            return cachedThumbnail
        case .preview:
            return cachedPreview
        }
    }

    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        switch type {
        case .thumbnail:
            completion(loadThumbnailResult)
        case .preview:
            completion(loadPreviewResult)
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            loadThumbnail(for: node, type: type, completion: promise)
        }
    }
    
    func loadThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    func loadPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity> {
        loadPrevieResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    func thumbnailPlaceholderFileType(forNodeName: String) -> MEGAFileType {
        placeholderFileType
    }
}
