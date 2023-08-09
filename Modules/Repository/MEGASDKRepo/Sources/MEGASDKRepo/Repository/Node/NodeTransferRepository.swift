import Combine
import MEGADomain
import MEGASdk

public final class NodeTransferRepository: NSObject, NodeTransferRepositoryProtocol {
    public static var newRepo: NodeTransferRepository {
        NodeTransferRepository(
            sdk: MEGASdk.sharedSdk,
            sharedFolderSdk: MEGASdk.sharedFolderLinkSdk
        )
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    
    private let transferResultSourcePublisher = PassthroughSubject<Result<TransferEntity, TransferErrorEntity>, Never>()
    public var transferResultPublisher: AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never> {
        transferResultSourcePublisher.eraseToAnyPublisher()
    }
    
    public init(sdk: MEGASdk, sharedFolderSdk: MEGASdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
    }
    
    public func registerMEGATransferDelegate() async {
        sdk.add(self as (any MEGATransferDelegate))
    }
    
    public func deRegisterMEGATransferDelegate() async {
        sdk.remove(self as (any MEGATransferDelegate))
    }
    
    public func registerMEGASharedFolderTransferDelegate() async {
        sharedFolderSdk.add(self as (any MEGATransferDelegate))
    }
    
    public func deRegisterMEGASharedFolderTransferDelegate() async {
        sharedFolderSdk.remove(self as (any MEGATransferDelegate))
    }
}

// MARK: - MEGATransferDelegate
extension NodeTransferRepository: MEGATransferDelegate {
    public func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard error.type == .apiOk else {
            transferResultSourcePublisher.send(.failure(error.toTransferErrorEntity() ?? .generic))
            return
        }
        transferResultSourcePublisher.send(.success(transfer.toTransferEntity()))
    }
}
