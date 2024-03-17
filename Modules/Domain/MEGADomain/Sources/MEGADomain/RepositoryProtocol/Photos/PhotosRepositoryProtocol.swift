import MEGASwift

public protocol PhotosRepositoryProtocol: SharedRepositoryProtocol, Sendable {
    /// The async sequence will yield the updated photos once cache is updated.
    /// - Returns: AnyAsyncSequence with the updated photo nodes including change types
    func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]>
    /// Load photos if local source does not contain it otherwise return local source data
    /// - Returns: Photo Nodes
    /// - Throws: `NodeErrorEntity` or `CancellationError`
    func allPhotos() async throws -> [NodeEntity]
    /// Load photo if local source does not contain it otherwise return local source data
    /// - Parameters:
    ///   - handle: The photo node handle entity
    /// - Returns: Photo Nodes
    /// - Throws: `NodeErrorEntity` or `CancellationError`
    func photo(forHandle handle: HandleEntity) async -> NodeEntity?
}
