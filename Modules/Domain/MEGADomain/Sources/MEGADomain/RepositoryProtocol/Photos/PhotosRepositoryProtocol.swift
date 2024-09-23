import MEGASwift

public protocol PhotosRepositoryProtocol: Sendable {
    /// The async sequence will yield the updated photos once cache is updated.
    /// - Returns: AnyAsyncSequence with the updated photo nodes including change types
    func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]>
    /// Load photos if local source does not contain it otherwise return local source data
    /// - Parameter excludeSensitive: Determines if sensitive nodes should be excluded
    /// - Returns: Photo Nodes
    /// - Throws: `NodeErrorEntity` or `CancellationError`
    func allPhotos(excludeSensitive: Bool) async throws -> [NodeEntity]
    /// Load photo if local source does not contain it otherwise return local source data
    /// - Parameters:
    ///   - handle: The photo node handle entity
    ///   - excludeSensitive: Determines if sensitive nodes should be excluded
    /// - Returns: Photo Node if it can be found and is not in rubbish otherwise nil
    /// - Throws: `NodeErrorEntity` or `CancellationError`
    func photo(forHandle handle: HandleEntity, excludeSensitive: Bool) async -> NodeEntity?
}
