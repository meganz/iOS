import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

final class TransferInventoryUseCaseHelper: NSObject, Sendable {
    private let transferInventoryUseCase: any TransferInventoryUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let fileSystem: any FileSystemRepositoryProtocol
    private let store: MEGAStore

    init(
        transferInventoryUseCase: some TransferInventoryUseCaseProtocol = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository.newRepo, fileSystemRepository: FileSystemRepository.newRepo),
        nodeUseCase: some NodeUseCaseProtocol = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ),
        fileSystem: some FileSystemRepositoryProtocol = FileSystemRepository.newRepo,
        store: MEGAStore = MEGAStore.shareInstance()
    ) {
        self.transferInventoryUseCase = transferInventoryUseCase
        self.nodeUseCase = nodeUseCase
        self.fileSystem = fileSystem
        self.store = store
    }

    func completedTransfers() -> [TransferEntity] {
        transferInventoryUseCase.completedTransfers(filteringUserTransfers: false)
            .filter {
                let node = nodeUseCase.nodeForHandle($0.nodeHandle) ?? $0.publicNode
                return node?.isFile ?? false && ($0.type == .upload || $0.path?.hasPrefix(FileSystemRepository.newRepo.documentsDirectory().path) ?? false || $0.appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false || $0.appData?.contains(TransferMetaDataEntity.exportFile.rawValue) ?? false)
            }
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
