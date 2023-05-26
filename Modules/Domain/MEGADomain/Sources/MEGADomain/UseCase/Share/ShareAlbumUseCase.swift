import Foundation

public protocol ShareAlbumUseCaseProtocol {
    func shareAlbumLink(_ album: AlbumEntity) async throws -> String?
    func removeSharedLink(forAlbum album: AlbumEntity) async throws
}

public struct ShareAlbumUseCase: ShareAlbumUseCaseProtocol {
    private let shareAlbumRepository: ShareAlbumRepositoryProtocol
    
    public init(shareAlbumRepository: ShareAlbumRepositoryProtocol) {
        self.shareAlbumRepository = shareAlbumRepository
    }
    
    public func shareAlbumLink(_ album: AlbumEntity) async throws -> String? {
        guard album.type == .user else {
            throw ShareAlbumErrorEntity.invalidAlbumType
        }
        return try await shareAlbumRepository.shareAlbumLink(album)
    }
    
    public func removeSharedLink(forAlbum album: AlbumEntity) async throws {
        guard album.type == .user else {
            throw ShareAlbumErrorEntity.invalidAlbumType
        }
        try await shareAlbumRepository.removeSharedLink(forAlbumId: album.id)
    }
}
