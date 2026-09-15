public enum TransferEventEntity: Sendable {
    case start(TransferEntity)
    case folderUpdate(FolderTransferUpdateEntity)
    case update(TransferEntity)
    case finish(TransferEntity)
}

public extension TransferEventEntity {
    var isTerminal: Bool {
        if case .finish = self {
            true
        } else {
            false
        }
    }
}
