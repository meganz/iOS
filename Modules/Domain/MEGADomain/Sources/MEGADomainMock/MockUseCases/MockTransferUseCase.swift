import Foundation
import MEGADomain

public final class MockTransferUseCase: TransferUseCaseProtocol, @unchecked Sendable {
    public var cancelDownloadTransfers_calledTimes = 0
    public var cancelUploadTransfers_calledTimes = 0

    public var stubbedDownloadTransfer: TransferEntity?
    public var stubbedUploadTransfer: TransferEntity?

    public var downloadError: (any Error)?
    public var uploadError: (any Error)?
    public var cancelDownloadError: (any Error)?
    public var cancelUploadError: (any Error)?
    public var cancelFolderLinkError: (any Error)?

    public init(
        stubbedDownloadTransfer: TransferEntity? = nil,
        stubbedUploadTransfer: TransferEntity? = nil,
        downloadError: (any Error)? = nil,
        uploadError: (any Error)? = nil,
        cancelDownloadError: (any Error)? = nil,
        cancelUploadError: (any Error)? = nil,
        cancelFolderLinkError: (any Error)? = nil
    ) {
        self.stubbedDownloadTransfer = stubbedDownloadTransfer
        self.stubbedUploadTransfer = stubbedUploadTransfer
        self.downloadError = downloadError
        self.uploadError = uploadError
        self.cancelDownloadError = cancelDownloadError
        self.cancelUploadError = cancelUploadError
        self.cancelFolderLinkError = cancelFolderLinkError
    }

    private func performTransferOperation(
        error: (any Error)?,
        stubbedResult: TransferEntity?,
        startHandler: ((TransferEntity) -> Void)?,
        progressHandler: ((TransferEntity) -> Void)?
    ) throws -> TransferEntity {
        if let error = error { throw error }
        guard let result = stubbedResult else {
            fatalError("Stubbed result must be set before calling transfer operation")
        }
        startHandler?(result)
        progressHandler?(result)
        return result
    }

    public func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity = .renameNewWithSuffix,
        startHandler: ((TransferEntity) -> Void)? = nil,
        progressHandler: ((TransferEntity) -> Void)? = nil
    ) async throws -> TransferEntity {
        try performTransferOperation(
            error: downloadError,
            stubbedResult: stubbedDownloadTransfer,
            startHandler: startHandler,
            progressHandler: progressHandler
        )
    }

    public func uploadFile(
        at fileUrl: URL,
        to parent: NodeEntity,
        startHandler: ((TransferEntity) -> Void)? = nil,
        progressHandler: ((TransferEntity) -> Void)? = nil
    ) async throws -> TransferEntity {
        try performTransferOperation(
            error: uploadError,
            stubbedResult: stubbedUploadTransfer,
            startHandler: startHandler,
            progressHandler: progressHandler
        )
    }

    public func cancelDownloadTransfers() async throws {
        cancelDownloadTransfers_calledTimes += 1
        if let cancelDownloadError { throw cancelDownloadError }
    }

    public func cancelUploadTransfers() async throws {
        cancelUploadTransfers_calledTimes += 1
        if let cancelUploadError { throw cancelUploadError }
    }
}
