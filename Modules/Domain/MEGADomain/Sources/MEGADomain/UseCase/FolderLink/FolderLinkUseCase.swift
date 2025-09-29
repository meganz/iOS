import MEGASwift

public enum FolderLinkUnavailableReason: Sendable, Equatable {
    case downETD
    case userETDSuspension
    case copyrightSuspension
    case generic
    case expired
}

public enum FolderLinkErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(FolderLinkUnavailableReason)
    case invalidDecryptionKey
    case decryptionKeyRequired
    case fetchNodesFailed
}

public protocol FolderLinkUseCaseProtocol: Sendable {
    var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> { get }
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    var fetchNodesRequestStartUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, FolderLinkErrorEntity>> { get }
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
    
    public var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, FolderLinkErrorEntity>> {
        requestStatesRepository
            .folderLinkRequestFinishUpdates
            .compactMap { response -> Result<RequestEntity, FolderLinkErrorEntity>? in
                if response.isSuccess {
                    return .success(response.requestEntity)
                } else {
                    let error = response.error
                    let requestEntity = response.requestEntity
                    return if error.hasExtraInfo {
                        if error.linkError == .downETD {
                            .failure(.linkUnavailable(.downETD))
                        } else if error.userError == .etdSuspension {
                            .failure(.linkUnavailable(.userETDSuspension))
                        } else if error.userError == .copyrightSuspension {
                            .failure(.linkUnavailable(.copyrightSuspension))
                        } else {
                            .failure(.linkUnavailable(.generic))
                        }
                    } else {
                        switch error.type {
                        case .badArguments:
                            if requestEntity.type == .login {
                                .failure(.invalidDecryptionKey)
                            } else if requestEntity.type == .fetchNodes {
                                .failure(.linkUnavailable(.generic))
                            } else {
                                nil
                            }
                        case .resourceExpired:
                            .failure(.linkUnavailable(.expired))
                        case .resourceNotExists:
                            if requestEntity.type == .fetchNodes || requestEntity.type == .login {
                                .failure(.linkUnavailable(.generic))
                            } else {
                                nil
                            }
                        case .incompleteRequest:
                               .failure(.decryptionKeyRequired)
                        default:
                            if requestEntity.type == .login {
                                .failure(.linkUnavailable(.generic))
                            } else if requestEntity.type == .fetchNodes {
                                .failure(.fetchNodesFailed)
                            } else {
                                nil
                            }
                        }
                    }
                }
            }
            .eraseToAnyAsyncSequence()
    }
}
