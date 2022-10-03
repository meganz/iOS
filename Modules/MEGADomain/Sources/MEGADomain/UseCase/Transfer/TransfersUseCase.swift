import Foundation

// MARK: - Use case protocol -
public protocol TransfersUseCaseProtocol {
    func transfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity]
    func documentsDirectory() -> URL
}

// MARK: - Use case implementation -
public struct TransfersUseCase<T: TransfersRepositoryProtocol, U: FileSystemRepositoryProtocol>: TransfersUseCaseProtocol {
    
    private let transfersRepository: T
    private let fileSystemRepository: U

    public init(transfersRepository: T, fileSystemRepository: U) {
        self.transfersRepository = transfersRepository
        self.fileSystemRepository = fileSystemRepository
    }
    
    public func transfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transfersRepository.transfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }

    public func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transfersRepository.downloadTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    public func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transfersRepository.uploadTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    public func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        let transfers = transfersRepository.completedTransfers()
        if filteringUserTransfers {
            return filterUserTransfers(transfers)
        } else {
            return transfers
        }
    }
    
    private func filterUserTransfers(_ transfers: [TransferEntity]) -> [TransferEntity] {
        transfers.filter {
            $0.type == .upload || isOfflineTransfer($0) || isExportFileTransfer($0) || isSaveToPhotosAppTransfer($0) || isSaveToPhotosAppTransfer($0)
        }
    }
    
    private func isOfflineTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.path?.hasPrefix(fileSystemRepository.documentsDirectory().path) ?? false
    }
    
    private func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(AppDataEntity.exportFile.rawValue) ?? false
    }
    
    private func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(AppDataEntity.saveInPhotos.rawValue) ?? false
    }
    
    public func documentsDirectory() -> URL {
        fileSystemRepository.documentsDirectory()
    }
}
