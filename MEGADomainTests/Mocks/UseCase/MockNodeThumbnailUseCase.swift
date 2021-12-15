@testable import MEGA
import Combine

struct MockNodeThumbnailUseCase: ThumbnailUseCaseProtocol {
    var getThumbnailResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var getPreviewResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var getThumbnailAndPreviewResult: (Result<(URL?, URL?), ThumbnailErrorEntity>) = .failure(.generic)
    var placeholderFileType: MEGAFileType = "generic"
    
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        completion(getThumbnailResult)
    }
    
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        completion(getPreviewResult)
    }
    
    func getCachedThumbnail(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            getCachedThumbnail(for: handle, completion: promise)
        }
    }
    
    func getCachedPreview(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            getCachedPreview(for: handle, completion: promise)
        }
    }
    
    func getCachedThumbnailAndPreview(for handle: MEGAHandle) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        getThumbnailAndPreviewResult
            .publisher
            .eraseToAnyPublisher()
    }
    
    func thumbnailPlaceholderFileType(forNodeName: String) -> MEGAFileType {
        placeholderFileType
    }
}
