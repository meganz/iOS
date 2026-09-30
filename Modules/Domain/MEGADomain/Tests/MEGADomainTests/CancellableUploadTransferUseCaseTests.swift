import Foundation
import MEGADomain
import MEGADomainMock
import Testing

/// Covers what the use case itself does: turn the transfers a screen asked for into the batch the
/// repository takes, hand it over, and report its transfer events as the state of the batch.
///
/// The reading of those events is `CancellableTransferStateMapper`'s, covered stage by stage in
/// `CancellableTransferStateMapperTests`; what is checked here is that an upload batch is read
/// through it at all. The fold that turns one transfer per item into a batch's events belongs to
/// `UploadFileRepository`, and lands with it.
@Suite("CancellableUploadTransferUseCase Tests")
struct CancellableUploadTransferUseCaseTests {

    // MARK: - Helpers

    private let uploadsFolder = URL(fileURLWithPath: "/Uploads")

    private func makeSUT(
        _ repository: MockUploadFileRepository,
        fileSystemRepository: MockFileSystemRepository = MockFileSystemRepository(movedNode: true)
    ) -> CancellableUploadTransferUseCase {
        CancellableUploadTransferUseCase(
            uploadFileRepository: repository,
            fileSystemRepository: fileSystemRepository,
            fileCacheRepository: MockFileCacheRepository(tempFolder: uploadsFolder)
        )
    }

    private func makeTransfer(
        _ name: String,
        isFile: Bool = true,
        parentHandle: HandleEntity = 1
    ) -> CancellableTransferEntity {
        CancellableTransferEntity(
            parentHandle: parentHandle,
            localFileURL: URL(fileURLWithPath: "/tmp/\(name)"),
            isFile: isFile,
            type: .upload,
            uploadOptions: UploadOptionsEntity()
        )
    }

    private func states(
        from repository: MockUploadFileRepository,
        transfers: [CancellableTransferEntity] = [],
        fileSystemRepository: MockFileSystemRepository = MockFileSystemRepository(movedNode: true)
    ) async -> [CancellableTransferStateEntity] {
        var collected = [CancellableTransferStateEntity]()
        for await state in makeSUT(repository, fileSystemRepository: fileSystemRepository).start(transfers: transfers) {
            collected.append(state)
        }
        return collected
    }

    // MARK: - Building the batch

    @Test("Every upload is handed to the repository, carrying where it goes and what it is")
    func theBatchIsHandedToTheRepository() async throws {
        let repository = MockUploadFileRepository()
        let transfers = [makeTransfer("a.jpg"), makeTransfer("Docs", isFile: false, parentHandle: 7)]

        _ = await states(from: repository, transfers: transfers)

        let handedOver = try #require(repository.uploadedBatches.first)
        #expect(repository.uploadedBatches.count == 1)
        #expect(handedOver.map(\.localFileURL.lastPathComponent) == ["a.jpg", "Docs"])
        #expect(handedOver.map(\.isFile) == [true, false])
        #expect(handedOver.map(\.parentHandle) == [1, 7])
    }

    @Test("An upload with nothing to upload is left out of the batch")
    func anUploadWithoutALocalFileIsLeftOut() async throws {
        let repository = MockUploadFileRepository()
        let transfers: [CancellableTransferEntity] = [
            .init(type: .upload, uploadOptions: UploadOptionsEntity()),
            makeTransfer("a.jpg")
        ]

        _ = await states(from: repository, transfers: transfers)

        #expect(repository.uploadedBatches.first?.count == 1)
    }

    @Test("An upload with no options to upload it under is left out of the batch")
    func anUploadWithoutOptionsIsLeftOut() async throws {
        let repository = MockUploadFileRepository()
        let transfers: [CancellableTransferEntity] = [
            .init(localFileURL: URL(fileURLWithPath: "/tmp/a.jpg"), type: .upload)
        ]

        _ = await states(from: repository, transfers: transfers)

        #expect(repository.uploadedBatches.first?.isEmpty == true)
    }

    @Test("A download is left out of the batch")
    func aDownloadIsLeftOut() async throws {
        // Nothing sends one here -- a screen carries transfers of a single type -- but the entity
        // can describe one, and an upload batch has no place for it.
        let repository = MockUploadFileRepository()
        let transfers: [CancellableTransferEntity] = [
            .init(handle: 1, localFileURL: URL(fileURLWithPath: "/tmp/a.jpg"), type: .download)
        ]

        _ = await states(from: repository, transfers: transfers)

        #expect(repository.uploadedBatches.first?.isEmpty == true)
    }

    @Test("The batch is handed over even when its states are never read")
    func handsTheBatchOverWithoutBeingRead() async throws {
        // Asking for the states is what starts the batch, so a screen that drops the sequence has
        // still handed its uploads over -- it has only stopped hearing about them.
        let repository = MockUploadFileRepository()
        var handOvers = repository.handedOverBatches.makeAsyncIterator()

        _ = makeSUT(repository).start(transfers: [makeTransfer("a.jpg")])

        let handedOver = try #require(await handOvers.next())
        #expect(handedOver.map(\.localFileURL.lastPathComponent) == ["a.jpg"])
    }

    @Test("The batch is handed over once, however many states it reports")
    func handsTheBatchOverOnce() async {
        let repository = MockUploadFileRepository(batchEvents: [
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3),
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 3)
        ])

        _ = await states(from: repository, transfers: [makeTransfer("a.jpg")])

        #expect(repository.uploadedBatches.count == 1)
    }

    // MARK: - Moving the items into the Uploads folder

    @Test("Every item is moved into the Uploads folder, and the repository uploads the moved copy")
    func everyItemIsMovedBeforeUpload() async throws {
        let repository = MockUploadFileRepository()
        let fileSystem = MockFileSystemRepository(movedNode: true)
        let transfers = [makeTransfer("a.jpg"), makeTransfer("Docs", isFile: false, parentHandle: 7)]

        _ = await states(from: repository, transfers: transfers, fileSystemRepository: fileSystem)

        let expectedURLs = [uploadsFolder.appendingPathComponent("a.jpg"), uploadsFolder.appendingPathComponent("Docs")]
        #expect(fileSystem.movedFiles.map(\.source.path) == ["/tmp/a.jpg", "/tmp/Docs"])
        #expect(fileSystem.movedFiles.map(\.destination) == expectedURLs)
        let handedOver = try #require(repository.uploadedBatches.first)
        #expect(handedOver.map(\.localFileURL) == expectedURLs)
        #expect(handedOver.map(\.isFile) == [true, false])
        #expect(handedOver.map(\.parentHandle) == [1, 7])
    }

    @Test("A failed move fails the batch, uploads nothing and removes nothing")
    func aFailedMoveFailsTheBatch() async {
        let repository = MockUploadFileRepository()
        let fileSystem = MockFileSystemRepository(movedNode: false)

        let states = await states(from: repository, transfers: [makeTransfer("a.jpg")], fileSystemRepository: fileSystem)

        #expect(states == [.failed])
        #expect(repository.uploadedBatches.isEmpty)
        #expect(fileSystem.removeFileURLs.isEmpty)
    }

    @Test("A move that fails after others succeeded removes the items already moved, and stops moving")
    func aPartlyFailedMoveRemovesTheMovedItems() async {
        let repository = MockUploadFileRepository()
        let fileSystem = MockFileSystemRepository(
            movedNode: true,
            failingMoveSourceURLs: [URL(fileURLWithPath: "/tmp/b.jpg")]
        )
        let transfers = [makeTransfer("a.jpg"), makeTransfer("b.jpg"), makeTransfer("c.jpg")]

        let states = await states(from: repository, transfers: transfers, fileSystemRepository: fileSystem)

        #expect(states == [.failed])
        #expect(repository.uploadedBatches.isEmpty)
        #expect(fileSystem.movedFiles.map(\.source.lastPathComponent) == ["a.jpg", "b.jpg"])
        #expect(fileSystem.removeFileURLs == [uploadsFolder.appendingPathComponent("a.jpg")])
    }

    @Test("The moved items are removed once the batch finishes, even after the screen stopped reading")
    func theMovedItemsAreRemovedAfterTheBatchFinishes() async {
        // The mapper stops at the transferring stage. The finish comes after it.
        let repository = MockUploadFileRepository(batchEvents: [
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 2),
            .finish(TransferEntity())
        ])
        let fileSystem = MockFileSystemRepository(movedNode: true)

        let states = await states(from: repository, transfers: [makeTransfer("a.jpg"), makeTransfer("b.jpg")], fileSystemRepository: fileSystem)

        #expect(states == [.transferringFiles])
        await waitForRemovals(count: 2, in: fileSystem)
        #expect(Set(fileSystem.removeFileURLs) == [uploadsFolder.appendingPathComponent("a.jpg"), uploadsFolder.appendingPathComponent("b.jpg")])
    }

    @Test("The moved items are removed when the batch ends on an error")
    func theMovedItemsAreRemovedWhenTheBatchThrows() async {
        let repository = MockUploadFileRepository(batchEventsError: TransferErrorEntity.upload)
        let fileSystem = MockFileSystemRepository(movedNode: true)

        let states = await states(from: repository, transfers: [makeTransfer("a.jpg")], fileSystemRepository: fileSystem)

        #expect(states == [.failed])
        await waitForRemovals(count: 1, in: fileSystem)
        #expect(fileSystem.removeFileURLs == [uploadsFolder.appendingPathComponent("a.jpg")])
    }

    /// The removal runs in the relay task, so it can land after the last state.
    private func waitForRemovals(count: Int, in fileSystem: MockFileSystemRepository) async {
        for _ in 0..<1000 where fileSystem.removeFileURLs.count < count {
            try? await Task.sleep(nanoseconds: NSEC_PER_MSEC)
        }
    }

    // MARK: - Reading the batch state from its transfer events

    @Test("A transferring folder update means the batch is away")
    func aTransferringUpdateReportsTransferringFiles() async {
        let repository = MockUploadFileRepository(batchEvents: [
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 5)
        ])

        let states = await states(from: repository)

        #expect(states == [.transferringFiles])
    }

    @Test("The stages the batch goes through on the way are reported as it passes them")
    func theStagesOnTheWayAreReported() async {
        let repository = MockUploadFileRepository(batchEvents: [
            .folderUpdateEvent(stage: .none, folderCount: 9, fileCount: 9),
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3),
            .folderUpdateEvent(stage: .createTree, folderCount: 4, createdFolderCount: 1),
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 3)
        ])

        let states = await states(from: repository)

        #expect(states == [
            .scanning(name: "Docs", folderCount: 2, fileCount: 3),
            .creatingFolders(created: 1, total: 4),
            .transferringFiles
        ])
    }

    @Test("Start, byte progress and finish events say nothing about the batch")
    func nonFolderEventsAreIgnored() async {
        // They belong to the virtual transfer the batch is reported as, which carries no counts.
        let repository = MockUploadFileRepository(batchEvents: [
            .start(TransferEntity()),
            .update(TransferEntity()),
            .finish(TransferEntity())
        ])

        let states = await states(from: repository)

        #expect(states == [.transferringFiles])
    }

    @Test("A batch that ends without reporting its transferring stage still started what it had")
    func aBatchThatEndsWithoutTransferringIsStillHandedOver() async {
        // A screen waiting on a terminal state must be given one, whichever way the batch ended.
        let states = await states(from: MockUploadFileRepository())

        #expect(states == [.transferringFiles])
    }

    @Test("Nothing is reported after the batch says it is transferring")
    func nothingIsReportedAfterTransferringFiles() async {
        let repository = MockUploadFileRepository(batchEvents: [
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 1),
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 2)
        ])

        let states = await states(from: repository)

        #expect(states == [.transferringFiles])
    }

    // MARK: - Failure

    @Test("A batch that ends on an error reports failed")
    func aBatchThatThrowsReportsFailed() async {
        let repository = MockUploadFileRepository(batchEventsError: TransferErrorEntity.upload)

        let states = await states(from: repository)

        #expect(states == [.failed])
    }

    @Test("A batch that failed after reporting itself away is not walked back")
    func anErrorAfterTheHandOverIsNotWalkedBack() async {
        let repository = MockUploadFileRepository(
            batchEvents: [.folderUpdateEvent(stage: .transferringFiles, fileCount: 1)],
            batchEventsError: TransferErrorEntity.upload
        )

        let states = await states(from: repository)

        #expect(states == [.transferringFiles])
    }

    // MARK: - Cancelling

    @Test("Cancelling forwards to the repository")
    func cancellingForwardsToTheRepository() {
        let repository = MockUploadFileRepository()

        makeSUT(repository).cancel()

        #expect(repository.cancelUploadTransfers_calledTimes == 1)
    }
}
