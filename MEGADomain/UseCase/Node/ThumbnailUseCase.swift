import Combine

// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func getCachedThumbnail(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity>
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func getCachedPreview(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity>
    
    func getCachedThumbnailAndPreview(for handle: MEGAHandle) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity>
}

struct ThumbnailUseCase: ThumbnailUseCaseProtocol {
    private let repository: ThumbnailRepositoryProtocol
    
    init(repository: ThumbnailRepositoryProtocol) {
        self.repository = repository
    }
    
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        repository.getCachedThumbnail(for: handle, completion: completion)
    }
    
    func getCachedThumbnail(for handle: MEGAHandle) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            getCachedThumbnail(for: handle, completion: promise)
        }
    }
    
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        repository.getCachedPreview(for: handle, completion: completion)
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
}

