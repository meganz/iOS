
public protocol TransfersRepositoryProtocol {
    func transfers() -> [TransferEntity]
    func downloadTransfers() -> [TransferEntity]
    func uploadTransfers() -> [TransferEntity]
    func completedTransfers() -> [TransferEntity]
    func isExportFileTransfer(_ transfer: TransferEntity) -> Bool
    func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool
}

