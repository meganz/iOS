// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
}

struct ThumbnailUseCase: ThumbnailUseCaseProtocol {
    private let repository: ThumbnailRepositoryProtocol
    
    init(repository: ThumbnailRepositoryProtocol) {
        self.repository = repository
    }
    
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        repository.getCachedThumbnail(for: handle, completion: completion)
    }
    
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        repository.getCachedPreview(for: handle, completion: completion)
    }
}

