import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

@objc final class TransferInventoryUseCaseHelper: NSObject, Sendable {
    private let transferInventoryUseCase: any TransferInventoryUseCaseProtocol
    private let sdk: MEGASdk
    private let fileSystem: any FileSystemRepositoryProtocol
    private let store: MEGAStore

    init(
        transferInventoryUseCase: some TransferInventoryUseCaseProtocol = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository.newRepo, fileSystemRepository: FileSystemRepository.newRepo),
        sdk: MEGASdk = MEGASdk.shared,
        fileSystem: some FileSystemRepositoryProtocol = FileSystemRepository.newRepo,
        store: MEGAStore = MEGAStore.shareInstance()
    ) {
        self.transferInventoryUseCase = transferInventoryUseCase
        self.sdk = sdk
        self.fileSystem = fileSystem
        self.store = store
    }

    @objc func completedTransfers() -> [MEGATransfer] {
        if let list = sdk.completedTransfers as? [MEGATransfer] {
            return list.filter {
                let node: MEGANode? = sdk.node(forHandle: $0.nodeHandle) ?? $0.publicNode
                return node?.isFile() ?? false && ($0.type == .upload || $0.path?.hasPrefix(FileSystemRepository.newRepo.documentsDirectory().path) ?? false || $0.appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false || $0.appData?.contains(TransferMetaDataEntity.exportFile.rawValue) ?? false)
            }
        }
        return []
    }
    
    @objc func transfers() -> [MEGATransfer] {
        transferInventoryUseCase
            .transfers(filteringUserTransfers: true)
            .compactMap { sdk.transfer(byTag: $0.tag) }
    }
    
    func transfers() async -> [TransferEntity] {
        await transferInventoryUseCase.transfers(filteringUserTransfers: true)
    }
    
    @objc func queuedUploadTransfers() -> [String] {
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
