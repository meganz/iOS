import Foundation
import MEGADomain
import MEGASwift

public final class MockTransferRepository: TransferRepositoryProtocol, @unchecked Sendable {
    public let completedTransferUpdates: AnyAsyncSequence<TransferEntity>
    
    public var cancelDownloadTransfers_calledTimes: Int = 0
    public var cancelUploadTransfers_calledTimes: Int = 0
    
    public var stubbedDownloadTransfer: TransferEntity?
    public var stubbedUploadTransfer: TransferEntity?
    
    public var downloadError: (any Error)?
    public var uploadError: (any Error)?
    
    public init(
        completedTransfers: [TransferEntity] = [],
        stubbedDownloadTransfer: TransferEntity? = nil,
        stubbedUploadTransfer: TransferEntity? = nil,
        downloadError: (any Error)? = nil,
        uploadError: (any Error)? = nil
    ) {
        self.completedTransferUpdates = completedTransfers.async.eraseToAnyAsyncSequence()
        self.stubbedDownloadTransfer = stubbedDownloadTransfer
        self.stubbedUploadTransfer = stubbedUploadTransfer
        self.downloadError = downloadError
        self.uploadError = uploadError
    }
    
    public static var newRepo: MockTransferRepository {
        MockTransferRepository()
    }
    
    public func uploadFile(
        at fileUrl: URL,
        to parent: NodeEntity,
        startHandler: ((TransferEntity) -> Void)? = nil,
        progressHandler: ((TransferEntity) -> Void)? = nil
    ) async throws -> TransferEntity {
        if let error = uploadError { throw error }
        if let stub = stubbedUploadTransfer {
            startHandler?(stub)
            progressHandler?(stub)
            return stub
        }
        let transfer = TransferEntity(type: .upload, path: fileUrl.path, parentHandle: parent.handle)
        startHandler?(transfer)
        progressHandler?(transfer)
        return transfer
    }
    
    public func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity = .renameNewWithSuffix,
        startHandler: ((TransferEntity) -> Void)? = nil,
        progressHandler: ((TransferEntity) -> Void)? = nil
    ) async throws -> TransferEntity {
        if let error = downloadError { throw error }
        if let stub = stubbedDownloadTransfer {
            startHandler?(stub)
            progressHandler?(stub)
            return stub
        }
        let transfer = TransferEntity(type: .download, path: localUrl.path, nodeHandle: node.handle)
        startHandler?(transfer)
        progressHandler?(transfer)
        return transfer
    }
    
    public func cancelDownloadTransfers() async throws {
        cancelDownloadTransfers_calledTimes += 1
    }
    
    public func cancelUploadTransfers() async throws {
        cancelUploadTransfers_calledTimes += 1
    }
}
