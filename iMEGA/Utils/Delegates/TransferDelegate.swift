import MEGADomain

final class TransferDelegate: NSObject, MEGATransferDelegate {
    var start: ((TransferEntity) -> Void)?
    var progress: ((TransferEntity) -> Void)?
    var completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    var folderUpdate: ((FolderTransferUpdateEntity) -> Void)?
    
    init(
        start: ((TransferEntity) -> Void)? = nil,
        progress: ((TransferEntity) -> Void)? = nil,
        completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void,
        folderUpdate: ((FolderTransferUpdateEntity) -> Void)? = nil
    ) {
        self.start = start
        self.progress = progress
        self.completion = completion
        self.folderUpdate = folderUpdate
    }
    
    init(completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        self.completion = completion
    }


    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if let start = start {
            start(transfer.toTransferEntity())
        }
    }

    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        if let progress = progress {
            progress(transfer.toTransferEntity())
        }
    }

    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if let completion = completion {
            if error.type != .apiOk {
                if transfer.state == .cancelled {
                    completion(.failure(.cancelled))
                } else {
                    let transferErrorEntity = transfer.type == .upload ? TransferErrorEntity.upload : TransferErrorEntity.download
                    completion(.failure(transferErrorEntity))
                }
            } else {
                completion(.success(transfer.toTransferEntity()))
            }
        }
    }
    
    func onFolderTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer, stage: MEGATransferStage, folderCount: UInt, createdFolderCount: UInt, fileCount: UInt, currentFolder: String, currentFileLeafName: String) {
        if let folderUpdate = folderUpdate {
            folderUpdate(FolderTransferUpdateEntity(transfer: transfer.toTransferEntity(), stage: TransferStageEntity(transferStage: stage) ?? .none, folderCount: folderCount, createdFolderCount: createdFolderCount, fileCount: fileCount))
        }
    }
}
