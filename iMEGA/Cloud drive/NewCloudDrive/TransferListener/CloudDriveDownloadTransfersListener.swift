import MEGADomain
import MEGARepo
import MEGASwift

protocol DownloadTransfersListening: Sendable {
    var downloadedNodes: AnyAsyncSequence<NodeEntity> { get }
}

/// Dedicated listener object to listen to completed transfers via "Make available offline" action
final class CloudDriveDownloadTransfersListener: NSObject, DownloadTransfersListening {
    
    var downloadedNodes: AnyAsyncSequence<NodeEntity> {
        transfersListenerUsecase.completedTransfers.compactMap(self.processTransfer)
            .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    private let transfersListenerUsecase: any TransfersListenerUseCaseProtocol
    private let fileSystemRepo: any FileSystemRepositoryProtocol
    
    init(sdk: MEGASdk,
         transfersListenerUsecase: some TransfersListenerUseCaseProtocol,
         fileSystemRepo: some FileSystemRepositoryProtocol
    ) {
        self.sdk = sdk
        self.transfersListenerUsecase = transfersListenerUsecase
        self.fileSystemRepo = fileSystemRepo
        super.init()
    }
    
    func processTransfer(_ transfer: TransferEntity) -> NodeEntity? {
        // Note: SDK always trigger callbacks for downloaded nodes that are saved to any arbitrary path.
        // Here for CloudDrive we're only interested in nodes that are downloaded to `documentsDirectory()`
        guard !transfer.isStreamingTransfer,
              transfer.type == .download,
              let parentPath = transfer.parentPath,
              let parentPathUrl = URL(string: parentPath),
              parentPathUrl.relativePath == fileSystemRepo.documentsDirectory().relativePath else { return nil }
        return sdk.node(forHandle: transfer.nodeHandle)?.toNodeEntity()
    }
}
