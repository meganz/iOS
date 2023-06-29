import Foundation

public protocol ShareAlbumRepositoryProtocol: RepositoryProtocol {
    func shareAlbumLink(_ album: AlbumEntity) async throws -> String?
    func removeSharedLink(forAlbumId id: HandleEntity) async throws
    func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity
    func publicPhoto(forPhotoId id: HandleEntity) async throws -> NodeEntity
}
