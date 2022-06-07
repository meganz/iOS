protocol AlbumUseCaseProtocol {
    func loadCameraUploadNode() async throws -> NodeEntity?
}

struct AlbumUseCase<T: AlbumRepositoryProtocol>: AlbumUseCaseProtocol {
    private let albumRepository: T
    
    init(repository: T) {
        albumRepository = repository
    }
    
    func loadCameraUploadNode() async throws -> NodeEntity? {
        return try await albumRepository.loadCameraUploadNode()
    }
}
