import MEGASwift

public protocol FolderLinkUseCaseProtocol: Sendable {
    var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> { get }
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
}

public struct FolderLinkUseCase<T: TransferRepositoryProtocol, N: NodeRepositoryProtocol>: FolderLinkUseCaseProtocol {
    private let transferRepository: T
    private let nodeRepository: N
    
    public init(transferRepository: T, nodeRepository: N) {
        self.transferRepository = transferRepository
        self.nodeRepository = nodeRepository
    }
    
    public var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> {
        transferRepository
            .completedTransferUpdates
            .filter { $0.isStreamingTransfer == false && $0.type == .download }
            .map { $0.nodeHandle }
            .eraseToAnyAsyncSequence()
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.folderLinkNodeUpdates
    }
}
