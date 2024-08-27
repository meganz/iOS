import Foundation

// MARK: - Use case protocol -
public protocol TransferInventoryUseCaseProtocol: Sendable {
    @available(*, deprecated, message: "Use async version instead")
    func transfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func transfers(filteringUserTransfers: Bool) async -> [TransferEntity]
    func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func saveToPhotosTransfers(filteringUserTransfer: Bool) -> [TransferEntity]?
    func documentsDirectory() -> URL
}

// MARK: - Use case implementation -
public struct TransferInventoryUseCase<T: TransferInventoryRepositoryProtocol, U: FileSystemRepositoryProtocol>: TransferInventoryUseCaseProtocol {
    
    private let transferInventoryRepository: T
    private let fileSystemRepository: U

    public init(transferInventoryRepository: T, fileSystemRepository: U) {
        self.transferInventoryRepository = transferInventoryRepository
        self.fileSystemRepository = fileSystemRepository
    }
    
    public func transfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transferInventoryRepository.transfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    public func transfers(filteringUserTransfers: Bool) async -> [TransferEntity] {
        let transfers = await transferInventoryRepository.transfers()
        return if filteringUserTransfers {
            filterUserTransfers(transfers)
        } else {
            transfers
        }
    }

    public func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transferInventoryRepository.downloadTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    public func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transferInventoryRepository.uploadTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    public func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transferInventoryRepository.completedTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    public func saveToPhotosTransfers(filteringUserTransfer: Bool) -> [TransferEntity]? {
        let transfers = transfers(filteringUserTransfers: filteringUserTransfer)
        return transfers.filter(isSaveToPhotosAppTransfer)
    }
    
    private func filterUserTransfers(_ transfers: [TransferEntity]) -> [TransferEntity] {
        transfers.filter {
            $0.type == .upload || isOfflineTransfer($0) || isExportFileTransfer($0) || isSaveToPhotosAppTransfer($0)
        }
    }
    
    private func isOfflineTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.path?.hasPrefix(fileSystemRepository.documentsDirectory().path) ?? false
    }
    
    private func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transferInventoryRepository.isExportFileTransfer(transfer)
    }
    
    private func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transferInventoryRepository.isSaveToPhotosAppTransfer(transfer)
    }
    
    public func documentsDirectory() -> URL {
        fileSystemRepository.documentsDirectory()
    }
}
