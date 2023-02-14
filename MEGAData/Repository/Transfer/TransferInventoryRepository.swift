import MEGADomain

struct TransferInventoryRepository: TransferInventoryRepositoryProtocol {
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func transfers() -> [TransferEntity] {
        sdk.transfers.toTransferEntities()
    }
    
    func downloadTransfers() -> [TransferEntity] {
        sdk.downloadTransfers.toTransferEntities()
    }
    
    func uploadTransfers() -> [TransferEntity] {
        sdk.uploadTransfers.toTransferEntities()
    }
    
    func completedTransfers() -> [TransferEntity] {
        guard let completedTransfers = sdk.completedTransfers as? [MEGATransfer] else {
            return []
        }
        return completedTransfers.map { $0.toTransferEntity() }
    }
    
    func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(TransferMetaDataEntity.exportFile.rawValue) ?? false
    }
    
    func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false
    }
}
