public protocol TransferInventoryRepositoryProtocol {
    @available(*, deprecated, message: "Use async version instead")
    func transfers() -> [TransferEntity]
    func transfers() async -> [TransferEntity]
    func downloadTransfers() -> [TransferEntity]
    func uploadTransfers() -> [TransferEntity]
    func completedTransfers() -> [TransferEntity]
    func isExportFileTransfer(_ transfer: TransferEntity) -> Bool
    func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool
}
