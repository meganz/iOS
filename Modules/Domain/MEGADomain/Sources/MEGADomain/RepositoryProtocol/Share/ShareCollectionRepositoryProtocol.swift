import Foundation

public protocol ShareCollectionRepositoryProtocol: RepositoryProtocol, Sendable {
    func shareCollectionLink(_ collection: SetEntity) async throws -> String?
    func removeSharedLink(forCollectionId id: SetIdentifier) async throws
    /// Retrieve set and set entities for collection link
    /// - Parameter link: public collection link to retrieve Set and Set elements
    ///
    /// Request all information about the public Set (attributes and Elements) and cache copies of it until preview mode is stopped
    func publicCollectionContents(forLink link: String) async throws -> SharedCollectionEntity
    /// Stop collection link preview
    ///
    /// Clear the cached Set and SetElements for collection link in preview (publicCollectionContents)
    /// as well as stop including the URL parameter which allows downloading foreign nodes in SetElements
    func stopCollectionLinkPreview()
    func publicNode(_ collection: SetElementEntity) async throws -> NodeEntity?
    /// Copy public nodes to the destination folder provided
    /// - Parameter folder: folder to store copies of nodes
    /// - Parameter collections: public nodes to copy
    /// - Returns: Copied  nodes
    /// - Throws: `NodeErrorEntity` or `CopyOrMoveErrorEntity` error.
    func copyPublicNodes(toFolder folder: NodeEntity, nodes: [NodeEntity]) async throws -> [NodeEntity]
}
