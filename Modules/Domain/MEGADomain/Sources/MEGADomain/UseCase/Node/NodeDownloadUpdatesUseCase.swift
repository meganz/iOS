import AsyncAlgorithms
import MEGASwift

public enum DownloadProgress: Sendable {
    case start(Int64) // totalBytes
    case update(Int64) // transferredBytes
    case finish(Int64) // transferredBytes
}

public protocol NodeDownloadUpdatesUseCaseProtocol: Sendable {
    func startMonitoringDownloadCompletion(for nodes: [NodeEntity]) -> AnyAsyncSequence<NodeEntity>
    func startMonitoringDownloadProgress(for node: NodeEntity) -> AnyAsyncSequence<DownloadProgress>
}

public struct NodeDownloadUpdatesUseCase<T: NodeTransferRepositoryProtocol>: NodeDownloadUpdatesUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func startMonitoringDownloadCompletion(for nodes: [NodeEntity]) -> AnyAsyncSequence<NodeEntity> {
        repo
            .transferFinishUpdates
            .compactMap { $0.isSuccess ? $0.transferEntity : nil }
            .filter { $0.type == .download && !$0.isStreamingTransfer }
            .compactMap { transfer in nodes.first(where: { node in node.handle == transfer.nodeHandle }) }
            .eraseToAnyAsyncSequence()
    }
    
    public func startMonitoringDownloadProgress(for node: NodeEntity) -> AnyAsyncSequence<DownloadProgress> {
        let isDownloadTransfer: @Sendable (TransferEntity) -> Bool = {
            $0.nodeHandle == node.handle && $0.type == .download && !$0.isStreamingTransfer
        }
        
        let start = repo
            .transferStartUpdates
            .filter(isDownloadTransfer)
            .map({ DownloadProgress.start(Int64($0.totalBytes)) })
            .eraseToAnyAsyncSequence()
        
        let updates = repo
            .transferUpdates
            .filter(isDownloadTransfer)
            .map({ DownloadProgress.update(Int64($0.transferredBytes)) })
            .eraseToAnyAsyncSequence()
        
        let finish = repo
            .transferFinishUpdates
            .filter({ isDownloadTransfer($0.transferEntity) })
            .map { $0.get() }
            .map({ DownloadProgress.finish(Int64($0.transferredBytes)) })
            .eraseToAnyAsyncSequence()
        
        return merge(start, updates, finish).eraseToAnyAsyncSequence()
    }
}
