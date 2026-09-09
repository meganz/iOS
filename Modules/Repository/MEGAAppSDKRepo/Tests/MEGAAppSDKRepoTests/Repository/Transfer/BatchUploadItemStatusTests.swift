@testable import MEGAAppSDKRepo
import MEGADomain
import MEGADomainMock
import Testing

/// Covers when one item of a batch upload counts as away and when it counts as over.
///
/// The batch is reported as handed over once every item of it is away, and finished once every
/// item is over, so these two answers are what the whole fold rests on. Read here one callback at
/// a time, rather than through a batch, because what decides them is the kind of callback and
/// whether the item is a file -- eight answers that a batch only ever shows a few of at once.
@Suite("BatchUploadItemStatus Tests")
struct BatchUploadItemStatusTests {

    // MARK: - Helpers

    private func status(isFile: Bool, phase: BatchUploadItemStatus.Phase) -> BatchUploadItemStatus {
        BatchUploadItemStatus(index: 0, isFile: isFile, phase: phase)
    }

    private func transferring(_ event: TransferEventEntity, isFile: Bool) -> BatchUploadItemStatus {
        status(isFile: isFile, phase: .transferring(event))
    }

    // MARK: - An item nothing has been reported for

    @Test("An item the SDK has said nothing about is neither away nor over", arguments: [true, false])
    func anItemWithNoCallbackYetIsNeitherAwayNorOver(isFile: Bool) {
        // The standing every item of a batch is seeded with, and what keeps the batch from
        // reporting itself away before the SDK has answered for all of it.
        let status = status(isFile: isFile, phase: .none)

        #expect(!status.hasStartedTransferring)
        #expect(!status.hasFinishedTransferring)
        #expect(status.error == nil)
    }

    // MARK: - Being away

    @Test("A file is away as soon as anything at all is reported for it")
    func aFileIsAwayOnAnyCallback() {
        // A file has nothing to scan: the SDK has queued it by the time it says anything.
        #expect(transferring(.start(TransferEntity()), isFile: true).hasStartedTransferring)
        #expect(transferring(.update(TransferEntity()), isFile: true).hasStartedTransferring)
        #expect(transferring(.finish(TransferEntity()), isFile: true).hasStartedTransferring)
    }

    @Test("A folder is away only once it has reached its transferring stage", arguments: [
        (TransferStageEntity.none, false),
        (.scan, false),
        (.createTree, false),
        (.transferringFiles, true)
    ])
    func aFolderIsAwayOnlyAtItsTransferringStage(stage: TransferStageEntity, isAway: Bool) {
        // A folder's own start says only that its scan began, and its byte updates carry the stage
        // it is in, so both are read the same way: by the stage, not by the kind of callback.
        #expect(transferring(.folderUpdateEvent(stage: stage), isFile: false).hasStartedTransferring == isAway)
        #expect(
            transferring(.update(TransferEntity(stage: stage)), isFile: false).hasStartedTransferring == isAway
        )
    }

    @Test("A folder's start says only that its scan began")
    func aFoldersStartIsNotEnoughToBeAway() {
        #expect(!transferring(.start(TransferEntity(isFolderTransfer: true)), isFile: false).hasStartedTransferring)
    }

    @Test("A folder that has finished is away, whatever stage it got to")
    func aFolderThatFinishedIsAway() {
        // There is nothing left to wait for, so it must not hold the batch back.
        #expect(transferring(.finish(TransferEntity()), isFile: false).hasStartedTransferring)
    }

    @Test("An item that failed is away, being past waiting for", arguments: [true, false])
    func aFailedItemIsAway(isFile: Bool) {
        #expect(status(isFile: isFile, phase: .failed(TransferErrorEntity.upload)).hasStartedTransferring)
    }

    // MARK: - Being over

    @Test("An item is over when its transfer finishes, and not before", arguments: [true, false])
    func anItemIsOverOnlyWhenItsTransferFinishes(isFile: Bool) {
        // For a folder that is the whole tree, not the first file in it.
        #expect(!transferring(.start(TransferEntity()), isFile: isFile).hasFinishedTransferring)
        #expect(!transferring(.update(TransferEntity()), isFile: isFile).hasFinishedTransferring)
        #expect(
            !transferring(.folderUpdateEvent(stage: .transferringFiles), isFile: isFile).hasFinishedTransferring
        )
        #expect(transferring(.finish(TransferEntity()), isFile: isFile).hasFinishedTransferring)
    }

    @Test("An item that failed is over: nothing further is reported for it", arguments: [true, false])
    func aFailedItemIsOver(isFile: Bool) {
        #expect(status(isFile: isFile, phase: .failed(TransferErrorEntity.upload)).hasFinishedTransferring)
    }

    // MARK: - What ended the item

    @Test("Only a failed item carries an error")
    func onlyAFailedItemCarriesAnError() {
        #expect(status(isFile: true, phase: .none).error == nil)
        #expect(transferring(.finish(TransferEntity()), isFile: true).error == nil)
        #expect(
            status(isFile: true, phase: .failed(TransferErrorEntity.cancelled)).error as? TransferErrorEntity
                == .cancelled
        )
    }
}
