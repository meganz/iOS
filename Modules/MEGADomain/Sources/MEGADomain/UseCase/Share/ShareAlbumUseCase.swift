import Foundation

public protocol ShareAlbumUseCaseProtocol {
    func share(album: AlbumEntity) async throws -> String?
    func disableShare(album: AlbumEntity) async throws
}

public struct ShareAlbumUseCase: ShareAlbumUseCaseProtocol {
    private let shareAlbumRepository: ShareAlbumRepositoryProtocol
    
    public init(shareAlbumRepository: ShareAlbumRepositoryProtocol) {
        self.shareAlbumRepository = shareAlbumRepository
    }
    
    public func share(album: AlbumEntity) async throws -> String? {
        guard album.type == .user else {
            throw ShareAlbumErrorEntity.invalidAlbumType
        }
        return try await shareAlbumRepository.shareAlbum(by: album.id)
    }
    
    public func disableShare(album: AlbumEntity) async throws {
        guard album.type == .user else {
            throw ShareAlbumErrorEntity.invalidAlbumType
        }
        try await shareAlbumRepository.disableAlbumShare(by: album.id)
    }
}
