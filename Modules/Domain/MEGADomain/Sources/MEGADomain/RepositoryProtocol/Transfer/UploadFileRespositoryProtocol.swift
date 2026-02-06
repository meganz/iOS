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

    /// Uploads a file from a specified URL to a parent folder.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - parent: The handle of the parent folder.
    ///   - fileName: An optional name for the file.
    ///   - appData: Optional application data.
    ///   - isSourceTemporary: A Boolean indicating whether the source file is temporary.
    ///   - startFirst: A Boolean indicating whether the upload should start first in the queue.
    ///   - start: An optional closure called when the upload starts.
    ///   - update: An optional closure called to update the progress of the upload.
    ///   - completion: An optional closure called upon completion of the upload.
    func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        fileName: String?,
        appData: String?,
        isSourceTemporary: Bool,
        startFirst: Bool,
        start: ((TransferEntity) -> Void)?,
        update: ((TransferEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    )
    
    /// Uploads a file from a specified URL to a parent folder.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - parent: The handle of the parent folder.
    ///   - uploadOptions: the uploadOptionsm
    ///   - start: An optional closure called when the upload starts.
    ///   - progress: An optional closure called to update the progress of the upload.
    ///   - completion: An optional closure called upon completion of the upload.
    func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?,
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
    
    /// Cancels a specified transfer.
    ///
    /// - Parameter transfer: The transfer entity to cancel.
    /// - Throws: An error if the cancellation fails.
    func cancel(transfer: TransferEntity) async throws

    /// Cancels all upload transfers.
    func cancelUploadTransfers()
}
