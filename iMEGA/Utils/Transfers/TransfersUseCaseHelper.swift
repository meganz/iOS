@objc final class TransferUseCaseHelper: NSObject {
    private let transfersUseCase = TransfersUseCase(repo: TransfersRepository(sdk: MEGASdkManager.sharedMEGASdk()))
    private let sharedFolderTransfersUseCase = TransfersUseCase(repo: TransfersRepository(sdk: MEGASdkManager.sharedMEGASdkFolder()))
    
    @objc func completedTransfers() -> [MEGATransfer] {
        if let list = MEGASdkManager.sharedMEGASdk().completedTransfers as? [MEGATransfer] {
            return list.filter {
                let node: MEGANode? = MEGASdkManager.sharedMEGASdk().node(forHandle: $0.nodeHandle) ?? $0.publicNode
                return $0.type == .upload || $0.path?.hasPrefix(Helper.relativePathForOffline()) ?? false && node?.isFile() ?? false 
            }
        }
        return []
    }
    
    @objc func transfers() -> [MEGATransfer] {
        let transfers = transfersUseCase.transfers(filteringUserTransfers: true)
        let sharedFolderTransfers = sharedFolderTransfersUseCase.transfers(filteringUserTransfers: true)
        let megaTransfers = transfers.compactMap { MEGASdkManager.sharedMEGASdk().transfer(byTag: $0.tag) }
        let sharedFolderMegaTransfers = sharedFolderTransfers.compactMap { MEGASdkManager.sharedMEGASdkFolder().transfer(byTag: $0.tag) }
        return megaTransfers + sharedFolderMegaTransfers
    }
}
