import Foundation

public protocol ShareAlbumRepositoryProtocol: RepositoryProtocol {
    func shareAlbum(by id: HandleEntity) async throws -> String?
    func disableAlbumShare(by id: HandleEntity) async throws
    func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity
}
