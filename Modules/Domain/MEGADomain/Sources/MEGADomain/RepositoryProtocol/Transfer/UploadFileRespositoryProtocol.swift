import Foundation
import MEGASwift

public protocol UploadFileRepositoryProtocol: Sendable {
    /// Checks if a file with the given name exists under the specified parent folder.
    ///
    /// - Parameters:
    ///   - name: The name of the file to check.
    ///   - parentHandle: The handle of the parent folder.
    /// - Returns: A Boolean indicating whether the file exists.
    func hasExistFile(
        name: String,
        parentHandle: HandleEntity
    ) -> Bool

    /// Returns a unique file name in the given parent folder.
    ///
    /// If `name` does not collide with any existing child node, it is returned as-is.
    /// Otherwise, a `_1`, `_2`, … suffix is appended before the extension until the name is unique.
    ///
    /// - Parameters:
    ///   - name: The proposed file name.
    ///   - parentHandle: The handle of the parent folder to check against.
    /// - Returns: A file name guaranteed to be unique within the parent folder.
    func resolvedFileName(
        _ name: String,
        inParent parentHandle: HandleEntity
    ) async -> String
    
    /// Uploads a file from a specified URL to a parent folder.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - parent: The handle of the parent folder.
    ///   - uploadOptions: the uploadOptionsm
    ///   - start: An optional closure called when the upload starts.
    ///   - progress: An optional closure called to update the progress of the upload.
    ///   - temporaryError: An optional closure called when the upload stalls and the SDK keeps retrying it.
    ///   - completion: An optional closure called upon completion of the upload.
    func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?,
        temporaryError: ((TransferEntity, ErrorEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    )
    
    /// Uploads a file from a specified URL to a parent folder asynchronously.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - parent: The node entity representing the parent folder.
    ///   - uploadOptions: Configuration options for the upload, including file name, app data, source handling, and priority settings.
    ///   - start: An optional closure called when the upload starts, providing the transfer entity.
    ///   - progress: An optional closure called periodically to report upload progress, providing the updated transfer entity.
    /// - Returns: The transfer entity representing the completed upload.
    /// - Throws: A `TransferErrorEntity` if the upload fails.
    func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity

    /// Uploads a support file from a specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the support file to upload.
    ///   - start: A closure called when the upload starts.
    ///   - progress: A closure called to update the progress of the upload.
    /// - Returns: The transfer entity representing the upload.
    /// - Throws: An error if the upload fails.
    func uploadSupportFile(_ url: URL) async throws -> AnyAsyncSequence<FileUploadEvent>
    
    /// Uploads a batch of files and folders and reports the state of that batch.
    ///
    /// The mirror of `DownloadFileRepositoryProtocol.downloadProgress(batch:)` and, until the SDK gains a
    /// batch upload of its own, the stand-in for one: the events of the batch's items are folded
    /// here into the events of a single transfer, so that a caller reads an upload batch exactly
    /// as it reads a download one: folder updates that count the whole batch, and a
    /// transferring-files stage reached once every item of it has started.
    ///
    /// - Parameter batch: Every root of the batch, each with its own parent folder.
    /// - Returns: The batch's transfer events. Asking for the sequence is what starts the batch.
    ///   A batch that got nowhere ends the sequence with the error that stopped it, rather than
    ///   reporting the failure as an event, which is what `CancellableTransferStateMapper` reads
    ///   as the batch having failed.
    func upload(batch: [UploadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error>

    /// Cancels a specified transfer.
    ///
    /// - Parameter transfer: The transfer entity to cancel.
    /// - Throws: An error if the cancellation fails.
    func cancel(transfer: TransferEntity) async throws

    /// Cancels all upload transfers.
    func cancelUploadTransfers()
}
