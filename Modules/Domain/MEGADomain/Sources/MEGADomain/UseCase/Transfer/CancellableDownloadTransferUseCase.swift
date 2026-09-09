import Foundation
import MEGAFoundation
import MEGASwift

// MARK: - Use case implementation -

/// Downloads a batch of transfers into the offline documents folder.
///
/// The `.download`, `.downloadChat` and `.downloadFileLink` implementation of
/// `CancellableTransferUseCaseProtocol`. The whole batch is handed to the data layer at once, so
/// what is reported is the progress of the selection as a whole rather than of any file in it.
public struct CancellableDownloadTransferUseCase: CancellableTransferUseCaseProtocol {
    private let downloadFileRepository: any DownloadFileRepositoryProtocol
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    private let mapper: any CancellableTransferStateMapping
    
    public init(
        downloadFileRepository: some DownloadFileRepositoryProtocol,
        fileSystemRepository: some FileSystemRepositoryProtocol,
        mapper: some CancellableTransferStateMapping = CancellableTransferStateMapper(direction: .download)
    ) {
        self.downloadFileRepository = downloadFileRepository
        self.fileSystemRepository = fileSystemRepository
        self.mapper = mapper
    }

    public func start(transfers: [CancellableTransferEntity]) -> AnyAsyncSequence<CancellableTransferStateEntity> {
        let destinationFolder = fileSystemRepository.documentsDirectory()
        let batch = transfers.compactMap {
            $0.downloadBatchItemEntity(destinationFolder: destinationFolder)
        }
        
        MEGALog.log(level: .info, message: "[CancellableTransfer] downloading batch of \(batch.count) item(s)")

        return mapper.map(from: { [downloadFileRepository] in downloadFileRepository.download(batch: batch) })
    }
    
    public func cancel() {
        MEGALog.log(level: .info, message: "[CancellableTransfer] cancelling the download batch")
        downloadFileRepository.cancelDownloadTransfers()
    }
}

private extension CancellableTransferEntity {
    func downloadBatchItemEntity(destinationFolder: URL) -> DownloadBatchItemEntity? {
        let source: DownloadBatchItemEntity.Source? = switch type {
        case .download:
            .node(handle)
        case .downloadChat:
            .chatNode(handle: handle, messageId: messageId, chatId: chatId)
        case .downloadFileLink:
            if let fileLinkURL {
                .fileLink(FileLinkEntity(linkURL: fileLinkURL))
            } else {
                nil
            }
        case .upload:
            nil
        }
        
        guard let source else { return nil }
        return DownloadBatchItemEntity(
            source: source,
            destinationFolder: destinationFolder,
            name: name,
            appData: appData,
            startFirst: startFirst
        )
    }
}
