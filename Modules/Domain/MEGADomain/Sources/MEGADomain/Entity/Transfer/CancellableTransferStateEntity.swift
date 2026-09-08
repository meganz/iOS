/// The state of a batch of transfers that a cancellable transfer view cares about.
///
/// During a transfer:
/// - `scanning` and `creatingFolders` report the progress of their respective phases and are displayed in a modal alert.
/// - `transferringFiles` indicates that the progress alert should be dismissed.
/// - `failed` indicates that the transfer has failed.
///
/// `scanning` and `creatingFolders` are progress states and may be emitted any number of times.
/// The remaining cases are terminal states; exactly one of them ends the batch.
///
/// See more:
/// - Confluence: https://confluence.developers.mega.co.nz/display/SDK/Folder+controllers#Foldercontrollers-2-Batchconcept
/// - MR: https://code.developers.mega.co.nz/mobile/ios/iOS_dev/-/merge_requests/2546
public enum CancellableTransferStateEntity: Sendable, Equatable {
    /// A folder transfer is being scanned before its contents can be queued.
    case scanning(name: String, folderCount: UInt, fileCount: UInt)
    /// A folder transfer is recreating its folder tree in the destination.
    case creatingFolders(created: UInt, total: UInt)
    /// Every transfer in the batch started.
    case transferringFiles
    /// No transfer in the batch got away.
    case failed
}
