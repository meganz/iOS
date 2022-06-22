protocol AlbumListUseCaseProtocol {
    func loadCameraUploadNode() async throws -> NodeEntity?
}

struct AlbumListUseCase<T: AlbumRepositoryProtocol>: AlbumListUseCaseProtocol {
    private let albumRepository: T
    
    init(repository: T) {
        albumRepository = repository
    }
    
    func loadCameraUploadNode() async throws -> NodeEntity? {
        return try await albumRepository.loadCameraUploadNode()
    }
}
