public enum TransferEventEntity: Sendable {
    case start(TransferEntity)
    case folderUpdate(FolderTransferUpdateEntity)
    case update(TransferEntity)
    case finish(TransferEntity)
}
