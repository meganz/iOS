import MEGADomain
import MEGARepo
import MEGASDKRepo

@objc final class TransferInventoryUseCaseHelper: NSObject {
    private let transferInventoryUseCase = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository.newRepo, fileSystemRepository: FileSystemRepository.newRepo)
    private let sharedFolderTransferInventoryUseCase = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.sharedFolderLink), fileSystemRepository: FileSystemRepository.newRepo)
    
    @objc func completedTransfers() -> [MEGATransfer] {
        if let list = MEGASdk.shared.completedTransfers as? [MEGATransfer] {
            return list.filter {
                let node: MEGANode? = MEGASdk.shared.node(forHandle: $0.nodeHandle) ?? $0.publicNode
                return node?.isFile() ?? false && ($0.type == .upload || $0.path?.hasPrefix(FileSystemRepository.newRepo.documentsDirectory().path) ?? false || $0.appData?.contains(NSString().mnz_appDataToSaveInPhotosApp()) ?? false || $0.appData?.contains(NSString().mnz_appDataToExportFile()) ?? false)
            }
        }
        return []
    }
    
    @objc func transfers() -> [MEGATransfer] {
        let transfers = transferInventoryUseCase.transfers(filteringUserTransfers: true)
        let sharedFolderTransfers = sharedFolderTransferInventoryUseCase.transfers(filteringUserTransfers: true)
        let megaTransfers = transfers.compactMap { MEGASdk.shared.transfer(byTag: $0.tag) }
        let sharedFolderMegaTransfers = sharedFolderTransfers.compactMap { MEGASdk.sharedFolderLink.transfer(byTag: $0.tag) }
        return megaTransfers + sharedFolderMegaTransfers
    }
}
