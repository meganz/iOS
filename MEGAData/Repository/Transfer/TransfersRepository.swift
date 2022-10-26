import MEGADomain

struct TransfersRepository: TransfersRepositoryProtocol {
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func transfers() -> [TransferEntity] {
        sdk.transfers.mnz_transfersArrayFromTranferList().map { $0.toTransferEntity() }
    }
    
    func downloadTransfers() -> [TransferEntity] {
        sdk.downloadTransfers.mnz_transfersArrayFromTranferList().map { $0.toTransferEntity() }
    }
    
    func uploadTransfers() -> [TransferEntity] {
        sdk.uploadTransfers.mnz_transfersArrayFromTranferList().map { $0.toTransferEntity() }
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
