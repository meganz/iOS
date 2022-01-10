@testable import MEGA
import Combine

struct MockThumbnailUseCase: ThumbnailUseCaseProtocol {
    var loadThumbnailResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var loadPreviewResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var loadThumbnailAndPreviewResult: (Result<(URL?, URL?), ThumbnailErrorEntity>) = .failure(.generic)
    var placeholderFileType: MEGAFileType = "generic"
    var hasCachedThumbnail = false
    var hasCachedPreview = false
    var cachedThumbnail = URL(string: "https://MEGA.NZ")!
    var cachedPreview = URL(string: "https://MEGA.NZ")!
    
    func hasCachedThumbnail(for node: NodeEntity) -> Bool {
        hasCachedThumbnail
    }
    
    func hasCachedPreview(for node: NodeEntity) -> Bool {
        hasCachedPreview
    }
    
    func cachedThumbnail(for node: NodeEntity) -> URL {
        cachedThumbnail
    }
    
    func cachedPreview(for node: NodeEntity) -> URL {
        cachedPreview
    }
    
    func loadThumbnail(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        completion(loadThumbnailResult)
    }
    
    func loadPreview(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        completion(loadPreviewResult)
    }
    
    func loadThumbnail(for node: NodeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            loadThumbnail(for: node, completion: promise)
        }
    }
    
    func loadPreview(for node: NodeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            loadPreview(for: node, completion: promise)
        }
    }
    
    func loadThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    func thumbnailPlaceholderFileType(forNodeName: String) -> MEGAFileType {
        placeholderFileType
    }
}
