import MEGADomain

public extension TransferEventEntity {
    /// A folder progress event, for scripting a folder transfer's stages in tests.
    ///
    /// `name` becomes the transfer's file name, which is what the presentation layer reads as the
    /// name of what is being scanned.
    static func folderUpdateEvent(
        stage: TransferStageEntity,
        name: String = "",
        folderCount: UInt = 0,
        createdFolderCount: UInt = 0,
        fileCount: UInt = 0
    ) -> TransferEventEntity {
        .folderUpdate(
            FolderTransferUpdateEntity(
                transfer: TransferEntity(fileName: name),
                stage: stage,
                folderCount: folderCount,
                createdFolderCount: createdFolderCount,
                fileCount: fileCount
            )
        )
    }
}
