protocol AlbumUseCaseProtocol {
    func loadAlbums() async throws -> [NodeEntity]
}

struct AlbumUseCase<T: AlbumRepositoryProtocol>: AlbumUseCaseProtocol {
    private let albumRepository: T
    
    init(repository: T) {
        albumRepository = repository
    }
    
    func loadAlbums() async throws -> [NodeEntity] {
        return try await albumRepository.loadAlbums()
    }
}
