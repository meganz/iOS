import Foundation

public protocol ShareAlbumUseCaseProtocol {
    func shareAlbumLink(_ album: AlbumEntity) async throws -> String?
    func shareLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity: String]
    func removeSharedLink(forAlbum album: AlbumEntity) async throws
    func removeSharedLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity]
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
    
    public func shareLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity : String] {
        await withTaskGroup(of: (HandleEntity, String?).self) { group in
            albums.forEach { album in
                group.addTask {
                    return (album.id, try? await shareAlbumLink(album))
                }
            }
            return await group.reduce(into: [HandleEntity : String](), {
                $0[$1.0] = $1.1
            })
        }
    }
    
    public func removeSharedLink(forAlbum album: AlbumEntity) async throws {
        guard album.type == .user else {
            throw ShareAlbumErrorEntity.invalidAlbumType
        }
        try await shareAlbumRepository.removeSharedLink(forAlbumId: album.id)
    }
    
    public func removeSharedLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity] {
        await withTaskGroup(of: HandleEntity?.self) { group in
            albums.forEach { album in
                group.addTask {
                    do {
                        try await removeSharedLink(forAlbum: album)
                        return album.id
                    } catch {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [HandleEntity](), {
                if let removeShareLinkAlbumId = $1 { $0.append(removeShareLinkAlbumId) }
            })
        }
    }
}
