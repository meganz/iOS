import MEGADomain

protocol TransfersRepositoryProtocol {
    func transfers() -> [TransferEntity]
    func downloadTransfers() -> [TransferEntity]
    func uploadTransfers() -> [TransferEntity]
    func completedTransfers() -> [TransferEntity]
}

