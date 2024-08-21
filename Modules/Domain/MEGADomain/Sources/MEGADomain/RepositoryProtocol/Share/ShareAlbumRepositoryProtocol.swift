import Foundation

public protocol ShareAlbumRepositoryProtocol: RepositoryProtocol, Sendable {
    func shareAlbumLink(_ album: AlbumEntity) async throws -> String?
    func removeSharedLink(forAlbumId id: HandleEntity) async throws
    /// Retrieve set and set entities for album link
    /// - Parameter link: public album link to retrieve Set and Set elements
    ///
    /// Request all information about the public Set (attributes and Elements) and cache copies of it until preview mode is stopped
    func publicAlbumContents(forLink link: String) async throws -> SharedCollectionEntity
    /// Stop album link preview
    ///
    /// Clear the cached Set and SetElements for album link in preview (publicAlbumContents)
    /// as well as stop including the URL parameter which allows downloading foreign nodes in SetElements
    func stopAlbumLinkPreview()
    func publicPhoto(_ photo: SetElementEntity) async throws -> NodeEntity?
    /// Copy public photos to the destination folder provided
    /// - Parameter folder: folder to store copies of nodes
    /// - Parameter photos: public photos to copy
    /// - Returns: Copied photo nodes
    /// - Throws: `NodeErrorEntity` or `CopyOrMoveErrorEntity` error.
    func copyPublicPhotos(toFolder folder: NodeEntity, photos: [NodeEntity]) async throws -> [NodeEntity]
}
