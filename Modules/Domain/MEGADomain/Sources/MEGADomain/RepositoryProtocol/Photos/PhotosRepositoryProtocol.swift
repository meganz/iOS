import MEGASwift

public protocol PhotosRepositoryProtocol: SharedRepositoryProtocol, Sendable {
    /// Photo nodes that will yield when updates are loaded
    /// - Returns: AnyAsyncSequence with updated photo nodes
    var photosUpdated: AnyAsyncSequence<[NodeEntity]> { get async }
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
