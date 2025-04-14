import Foundation
import MEGASwift

public protocol TransferRepositoryProtocol: RepositoryProtocol, Sendable {
    var completedTransferUpdates: AnyAsyncSequence<TransferEntity> { get }
    
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity,
        startHandler: ((TransferEntity) -> Void)?,
        progressHandler: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity
    
    func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
    
    /// Cancels all ongoing download transfers.
    /// - Throws: An error if the cancellation of download transfers fails.
    func cancelDownloadTransfers() async throws
    /// Cancels all ongoing upload transfers.
    /// - Throws: An error if the cancellation of upload transfers fails.
    func cancelUploadTransfers() async throws
}
