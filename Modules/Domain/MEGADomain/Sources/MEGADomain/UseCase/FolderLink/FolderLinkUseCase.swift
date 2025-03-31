import MEGASwift

public protocol FolderLinkUseCaseProtocol: Sendable {
    var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> { get }
}

public struct FolderLinkUseCase<T: TransferRepositoryProtocol>: FolderLinkUseCaseProtocol {
    private let transferRepository: T
    
    public init(transferRepository: T) {
        self.transferRepository = transferRepository
    }
    
    public var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> {
        transferRepository
            .completedTransferUpdates
            .filter { $0.isStreamingTransfer == false && $0.type == .download }
            .map { $0.nodeHandle }
            .eraseToAnyAsyncSequence()
    }
}
