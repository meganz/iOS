import MEGASwift

/// Use case for monitoring transfer events, filtering out streaming and folder transfers
/// that are not counted towards general transfer progress.
///
/// This protocol provides async sequences for transfer events, allowing clients to observe
/// transfer starts, updates, temporary errors, and finishes. All events are filtered to exclude
/// streaming and folder transfers, as well as any transfers not relevant to general progress
/// (such as those not matching upload, offline, export, or save-to-photos criteria).
///
/// - Note: Filtering is performed using `isValidTransfer`, which checks transfer type and context.
public protocol TransferCounterUseCaseProtocol: Sendable {
    /// Provides updates when transfers start, excluding not valid transfers
    var transferStartUpdates: AnyAsyncSequence<TransferEntity> { get }
    
    /// Provides updates during transfer progress, excluding not valid transfers
    var transferUpdates: AnyAsyncSequence<TransferEntity> { get }
    
    /// Provides updates for temporary transfer errors, excluding not valid transfers
    var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> { get }
    
    /// Provides updates when transfers finish, excluding not valid transfers
    var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> { get }
}

public struct TransferCounterUseCase<T: NodeTransferRepositoryProtocol, U: TransferInventoryRepositoryProtocol, V: FileSystemRepositoryProtocol>: TransferCounterUseCaseProtocol {
    private let repo: T
    private let transferInventoryRepository: U
    private let fileSystemRepository: V
    
    public init(repo: T, transferInventoryRepository: U, fileSystemRepository: V) {
        self.repo = repo
        self.transferInventoryRepository = transferInventoryRepository
        self.fileSystemRepository = fileSystemRepository
    }
    
    public var transferStartUpdates: AnyAsyncSequence<TransferEntity> {
        repo
            .transferStartUpdates
            .filter(isValidTransfer)
            .eraseToAnyAsyncSequence()
    }
    
    public var transferUpdates: AnyAsyncSequence<TransferEntity> {
        repo
            .transferUpdates
            .filter(isValidTransfer)
            .eraseToAnyAsyncSequence()
    }
    
    public var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> {
        repo
            .transferTemporaryErrorUpdates
            .filter { isValidTransfer($0.transferEntity) }
            .eraseToAnyAsyncSequence()
    }
    
    public var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> {
        repo
            .transferFinishUpdates
            .filter { isValidTransfer($0.transferEntity) }
            .eraseToAnyAsyncSequence()
    }
    
    // MARK: - Private
    /// Determines if a transfer should be counted towards general progress.
    /// Excludes streaming and folder transfers, and includes uploads, offline, export, and save-to-photos transfers.
    private func isValidTransfer(_ transfer: TransferEntity) -> Bool {
        if transfer.isStreamingTransfer || transfer.isFolderTransfer {
            return false
        }
        return transfer.type == .upload
            || isOfflineTransfer(transfer)
            || isExportFileTransfer(transfer)
            || isSaveToPhotosAppTransfer(transfer)
    }
    
    private func isOfflineTransfer(_ transfer: TransferEntity) -> Bool {
        guard let path = transfer.path else { return false }
        return path.hasPrefix(fileSystemRepository.documentsDirectory().path)
    }
    
    private func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transferInventoryRepository.isExportFileTransfer(transfer)
    }
    
    private func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transferInventoryRepository.isSaveToPhotosAppTransfer(transfer)
    }
}
