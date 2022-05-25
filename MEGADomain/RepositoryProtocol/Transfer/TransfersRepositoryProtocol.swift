protocol TransfersRepositoryProtocol {
    func transfers() async -> [TransferEntity]
    func downloadTransfers() -> [TransferEntity]
    func uploadTransfers() -> [TransferEntity]
    func completedTransfers() -> [TransferEntity]
}

