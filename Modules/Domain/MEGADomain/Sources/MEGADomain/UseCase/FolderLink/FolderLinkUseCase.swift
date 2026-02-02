import MEGASwift

public enum FolderLinkUnavailableReason: Sendable, Equatable {
    case downETD
    case userETDSuspension
    case copyrightSuspension
    case generic
    case expired
}

public protocol FolderLinkUseCaseProtocol: Sendable {
    var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> { get }
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    var fileAttributesUpdates: AnyAsyncSequence<HandleEntity> { get }
}

public struct FolderLinkUseCase<T: TransferRepositoryProtocol, N: NodeRepositoryProtocol, R: RequestStatesRepositoryProtocol>: FolderLinkUseCaseProtocol {
    private let transferRepository: T
    private let nodeRepository: N
    private let requestStatesRepository: R
    
    public init(transferRepository: T, nodeRepository: N, requestStatesRepository: R) {
        self.transferRepository = transferRepository
        self.nodeRepository = nodeRepository
        self.requestStatesRepository = requestStatesRepository
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
    
    public var fetchNodesRequestStartUpdates: AnyAsyncSequence<RequestEntity> {
        requestStatesRepository
            .folderLinkRequestStartUpdates
            .filter { $0.type == .fetchNodes }
            .eraseToAnyAsyncSequence()
    }
    
    public var fileAttributesUpdates: AnyAsyncSequence<HandleEntity> {
        requestStatesRepository
            .folderLinkRequestFinishUpdates
            .filter { $0.isSuccess && $0.requestEntity.type == .getAttrFile }
            .map { $0.requestEntity.nodeHandle }
            .eraseToAnyAsyncSequence()
    }
}
