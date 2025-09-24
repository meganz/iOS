import MEGASwift

public protocol NodeDownloadUpdatesUseCaseProtocol: Sendable {
    func startMonitoringDownloadCompletion(for nodes: [NodeEntity]) -> AnyAsyncSequence<NodeEntity>
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
            .filter { $0.type == .download && !$0.isStreamingTransfer}
            .compactMap { transfer in nodes.first(where: { node in node.handle == transfer.nodeHandle }) }
            .eraseToAnyAsyncSequence()
    }
}
