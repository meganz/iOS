import Foundation
import MEGASwift

public protocol PhotoBrowserNodeDownloadUseCaseProtocol: Sendable {
    /// Downloads the full size image of `node` to exactly `destination`, and reports its transfer.
    ///
    /// The destination is a file path which the browser reads the image back from
    func downloadOriginalImage(
        for node: NodeEntity,
        to destination: URL
    ) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error>
}

public struct PhotoBrowserNodeDownloadUseCase<T: DownloadFileRepositoryProtocol>: PhotoBrowserNodeDownloadUseCaseProtocol {
    private let downloadFileRepository: T

    public init(downloadFileRepository: T) {
        self.downloadFileRepository = downloadFileRepository
    }

    public func downloadOriginalImage(
        for node: NodeEntity,
        to destination: URL
    ) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error> {
        downloadFileRepository.downloadBatchFileItemProgress(
            item: DownloadBatchItemEntity(
                source: .node(node.handle),
                destination: .file(destination)
            )
        )
    }
}
