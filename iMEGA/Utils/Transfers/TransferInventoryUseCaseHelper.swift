import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

final class TransferInventoryUseCaseHelper: NSObject, Sendable {
    private let transferInventoryUseCase: any TransferInventoryUseCaseProtocol
    private let sdk: MEGASdk
    private let nodeUseCase: any NodeUseCaseProtocol
    private let fileSystem: any FileSystemRepositoryProtocol
    private let store: MEGAStore

    init(
        transferInventoryUseCase: some TransferInventoryUseCaseProtocol = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository.newRepo, fileSystemRepository: FileSystemRepository.sharedRepo),
        sdk: MEGASdk = MEGASdk.shared,
        nodeUseCase: some NodeUseCaseProtocol = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ),
        fileSystem: some FileSystemRepositoryProtocol = FileSystemRepository.sharedRepo,
        store: MEGAStore = MEGAStore.shareInstance()
    ) {
        self.transferInventoryUseCase = transferInventoryUseCase
        self.sdk = sdk
        self.nodeUseCase = nodeUseCase
        self.fileSystem = fileSystem
        self.store = store
    }
    
    /// We use `MEGATransfer` directly—avoiding round-trip conversion from`TransferEntity` via `transferByTag(_:)`, which doesn’t return completed transfers by tag.
    func completedTransfers() -> [MEGATransfer] {
        if let list = sdk.completedTransfers as? [MEGATransfer] {
            return list.filter {
                let node = nodeUseCase.nodeForHandle($0.nodeHandle)?.toMEGANode(in: sdk) ?? $0.publicNode
                return node?.isFile() ?? false && ($0.type == .upload || $0.path?.hasPrefix(fileSystem.documentsDirectory().path) ?? false || $0.appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false || $0.appData?.contains(TransferMetaDataEntity.exportFile.rawValue) ?? false)
            }
        }
        return []
    }
    
    func transfers() -> [TransferEntity] {
        transferInventoryUseCase
            .transfers(filteringUserTransfers: true)
    }
    
    func transfers() async -> [TransferEntity] {
        await transferInventoryUseCase.transfers(filteringUserTransfers: true)
    }
    
    func queuedUploadTransfers() -> [String] {
        store.fetchUploadTransfers()?.compactMap { $0.localIdentifier } ?? []
    }
    
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        transferInventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
    }
    
    func documentsDirectory() -> URL {
        transferInventoryUseCase.documentsDirectory()
    }
    
    func removeAllUploadTransfers() {
        store.removeAllUploadTransfers()
    }
}
