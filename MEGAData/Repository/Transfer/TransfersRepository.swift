struct TransfersRepository: TransfersRepositoryProtocol {
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func transfers() -> [TransferEntity] {
        sdk.transfers.mnz_transfersArrayFromTranferList().map { TransferEntity(transfer: $0) }
    }
    
    func downloadTransfers() -> [TransferEntity] {
        sdk.downloadTransfers.mnz_transfersArrayFromTranferList().map { TransferEntity(transfer: $0) }
    }
    
    func uploadTransfers() -> [TransferEntity] {
        sdk.uploadTransfers.mnz_transfersArrayFromTranferList().map { TransferEntity(transfer: $0) }
    }
    
    func completedTransfers() -> [TransferEntity] {
        guard let completedTransfers = sdk.completedTransfers as? [MEGATransfer] else {
            return []
        }
        return completedTransfers.map { TransferEntity(transfer: $0) }
    }
}
