import Foundation
import Combine

// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func getCachedThumbnail(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity>
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func getCachedPreview(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity>
    func getCachedThumbnailAndPreview(for handle: MEGAHandle) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity>
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType
}

extension ThumbnailUseCase {
    static let `default` = ThumbnailUseCase(repository: ThumbnailRepository.default)
}

struct ThumbnailUseCase: ThumbnailUseCaseProtocol {
    private let repository: ThumbnailRepositoryProtocol
    private let fileTypes = FileTypes()
    
    init(repository: ThumbnailRepositoryProtocol) {
        self.repository = repository
    }
    
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            repository.getCachedThumbnail(for: handle, completion: completion)
        }
    }
    
    func getCachedThumbnail(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            getCachedThumbnail(for: handle, completion: promise)
        }
    }
    
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            repository.getCachedPreview(for: handle, completion: completion)
        }
    }
    
    func getCachedPreview(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            getCachedPreview(for: handle, completion: promise)
        }
    }
    
    func getCachedThumbnailAndPreview(for handle: MEGAHandle) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        getCachedThumbnail(for: handle)
            .map(Optional.some)
            .prepend(nil)
            .combineLatest(
                getCachedPreview(for: handle)
                    .map(Optional.some)
                    .prepend(nil)
            )
            .eraseToAnyPublisher()
    }
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType {
        fileTypes.fileType(forFileName: name)
    }
}

