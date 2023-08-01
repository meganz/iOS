import Foundation

public protocol ShareAlbumRepositoryProtocol: RepositoryProtocol {
    func shareAlbumLink(_ album: AlbumEntity) async throws -> String?
    func removeSharedLink(forAlbumId id: HandleEntity) async throws
    func publicAlbumContents(forLink link: String) async throws -> SharedAlbumEntity
    func publicPhoto(_ photo: SetElementEntity) async throws -> NodeEntity?
    /// Copy public photos to the destination folder provided
    /// - Parameter folder: folder to store copies of nodes
    /// - Parameter photos: public photos to copy
    /// - Returns: Copied photo nodes
    /// - Throws: `NodeErrorEntity` or `CopyOrMoveErrorEntity` error.
    func copyPublicPhotos(toFolder folder: NodeEntity, photos: [NodeEntity]) async throws -> [NodeEntity]
}
