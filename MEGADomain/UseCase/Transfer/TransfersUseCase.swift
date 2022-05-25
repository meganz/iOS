// MARK: - Use case protocol -
protocol TransfersUseCaseProtocol {
    func transfers(filteringUserTransfers: Bool) async -> [TransferEntity]
    func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
}

// MARK: - Use case implementation -
struct TransfersUseCase<T: TransfersRepositoryProtocol>: TransfersUseCaseProtocol {
    
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func transfers(filteringUserTransfers: Bool) async -> [TransferEntity] {
        let transfers = await repo.transfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }

    func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = repo.downloadTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = repo.uploadTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = repo.completedTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    private func filterUserTransfers(_ transfers: [TransferEntity]) -> [TransferEntity] {
        transfers.filter {
            $0.type == .upload || isOfflineTransfer($0) || isExportFileTransfer($0) || isSaveToPhotosAppTransfer($0)
        }
    }
    
    private func isOfflineTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.path?.hasPrefix(Helper.relativePathForOffline()) ?? false
    }
    
    private func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(NSString().mnz_appDataToExportFile()) ?? false
    }
    
    private func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(NSString().mnz_appDataToSaveInPhotosApp()) ?? false
    }
}
