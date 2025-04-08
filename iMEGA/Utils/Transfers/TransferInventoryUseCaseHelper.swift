import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

@objc final class TransferInventoryUseCaseHelper: NSObject, Sendable {
    private let transferInventoryUseCase = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository.newRepo, fileSystemRepository: FileSystemRepository.newRepo)
    
    @objc func completedTransfers() -> [MEGATransfer] {
        if let list = MEGASdk.shared.completedTransfers as? [MEGATransfer] {
            return list.filter {
                let node: MEGANode? = MEGASdk.shared.node(forHandle: $0.nodeHandle) ?? $0.publicNode
                return node?.isFile() ?? false && ($0.type == .upload || $0.path?.hasPrefix(FileSystemRepository.newRepo.documentsDirectory().path) ?? false || $0.appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false || $0.appData?.contains(TransferMetaDataEntity.exportFile.rawValue) ?? false)
            }
        }
        return []
    }
    
    @objc func transfers() -> [MEGATransfer] {
        let transfers = transferInventoryUseCase.transfers(filteringUserTransfers: true)
        let megaTransfers = transfers.compactMap { MEGASdk.shared.transfer(byTag: $0.tag) }
        return megaTransfers
    }
    
    func transfers() async -> [TransferEntity] {
        let transfers = await transferInventoryUseCase.transfers(filteringUserTransfers: true)
        return transfers
    }
    
    @objc func queuedUploadTransfers() -> [String] {
        let queueUploadTransfers = MEGAStore.shareInstance().fetchUploadTransfers()
        return queueUploadTransfers?.compactMap { $0.localIdentifier } ?? []
    }
    
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        transferInventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
    }
    
    func documentsDirectory() -> URL {
        transferInventoryUseCase.documentsDirectory()
    }
}
