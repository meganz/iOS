import MEGADomain
import MEGASdk
import MEGASwift

final class BatchDownloadTransferDelegate: NSObject, MEGATransferDelegate, @unchecked Sendable {
    private let onBatchItemFinish: @Sendable (TransferResponseEntity) -> Void
    private var batchTag: Int?
    private let lock: NSLock = NSLock()
    
    init(
        onBatchItemFinish: @Sendable @escaping (TransferResponseEntity) -> Void
    ) {
        self.onBatchItemFinish = onBatchItemFinish
    }
    
    func setBatchTag(_ tag: Int) {
        lock.withLock {
            guard batchTag == nil else { return }
            batchTag = tag
        }
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        let responseEntity: TransferResponseEntity? = lock.withLock {
            guard !transfer.isFolderTransfer, transfer.folderTransferTag == batchTag else { return nil }
            return TransferResponseEntity(transferEntity: transfer.toTransferEntity(), error: error.toErrorEntity())
        }
        
        guard let responseEntity else { return }
        onBatchItemFinish(responseEntity)
    }
}
