import Foundation
import MEGASwift

public protocol TransferRepositoryProtocol: RepositoryProtocol, Sendable {
    var completedTransferUpdates: AnyAsyncSequence<TransferEntity> { get }
    
    /// Downloads a node to a local URL with optional handlers for transfer events.
    ///
    /// This method initiates a download and uses closures to notify about transfer start and progress.
    /// The method completes when the download finishes, returning the final transfer entity.
    ///
    /// - Parameters:
    ///   - node: The node entity to download from the cloud storage.
    ///   - localUrl: The local file system URL where the node should be downloaded.
    ///   - collisionResolution: The strategy to use when a file already exists at the destination.
    ///   - startHandler: An optional closure called when the download starts, passing the initial transfer entity.
    ///   - progressHandler: An optional closure called periodically during the download with updated transfer progress.
    /// - Returns: The completed transfer entity with final transfer information.
    /// - Throws: An error if the download fails or cannot be initiated.
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity,
        startHandler: ((TransferEntity) -> Void)?,
        progressHandler: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity
    
    /// Downloads a node to a local URL and returns an async sequence of transfer events.
    ///
    /// This method initiates a download and returns an async sequence that emits transfer events
    /// throughout the download lifecycle, including start, progress updates, and completion.
    ///
    /// - Parameters:
    ///   - node: The node entity to download from the cloud storage.
    ///   - localUrl: The local file system URL where the node should be downloaded.
    ///   - collisionResolution: The strategy to use when a file already exists at the destination.
    /// - Returns: An async sequence that emits `TransferEventEntity` events during the download.
    /// - Throws: An error if the download cannot be initiated.
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity
    ) throws -> AnyAsyncSequence<TransferEventEntity>
    
    func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
    
    /// Cancels all ongoing download transfers.
    /// - Throws: An error if the cancellation of download transfers fails.
    func cancelDownloadTransfers() async throws
    /// Cancels all ongoing upload transfers.
    /// - Throws: An error if the cancellation of upload transfers fails.
    func cancelUploadTransfers() async throws
}
