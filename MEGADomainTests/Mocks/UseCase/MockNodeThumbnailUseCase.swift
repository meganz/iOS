@testable import MEGA

struct MockNodeThumbnailUseCase: ThumbnailUseCaseProtocol {
    var getThumbnailResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    var getPreviewResult: (Result<URL, ThumbnailErrorEntity>) = .failure(.generic)
    
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        completion(getThumbnailResult)
    }
    
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        completion(getPreviewResult)
    }
}
