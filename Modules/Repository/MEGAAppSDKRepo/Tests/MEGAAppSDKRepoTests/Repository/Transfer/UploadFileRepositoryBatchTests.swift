import Foundation
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing

/// Covers `UploadFileRepository.upload(batch:)` -- the fold that turns one transfer per selected
/// item into a single report for the batch.
///
/// What is folded is only whether the batch has started transferring. The whole selection is queued
/// at once, so its items scan and build their trees at overlapping times and no count taken across
/// them describes a stage the batch as a whole is in; the fold says nothing about them, and only
/// reports the batch started once every item has, finished once every item has, or failed when none
/// of them started.
///
/// Driven through `CancellableUploadTransferUseCase` rather than read as raw `TransferEventEntity`s:
/// `TransferEventEntity` is not `Equatable`, and what the fold is for is the state a screen ends up
/// showing. `MockSdk` scripts the transfer delegate callbacks the fold actually reacts to, so what
/// is under test here is the repository, with the use case as a thin, real reader of its output.
@Suite("UploadFileRepository.upload(batch:) Tests")
struct UploadFileRepositoryBatchTests {

    // MARK: - Helpers

    private func makeSUT(_ sdk: MockSdk) -> CancellableUploadTransferUseCase {
        CancellableUploadTransferUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk))
    }

    private func makeTransfer(_ name: String, isFile: Bool) -> CancellableTransferEntity {
        CancellableTransferEntity(
            parentHandle: 1,
            localFileURL: URL(fileURLWithPath: "/tmp/\(name)"),
            isFile: isFile,
            type: .upload,
            uploadOptions: UploadOptionsEntity()
        )
    }

    private func makeItem(
        _ name: String,
        isFile: Bool,
        parentHandle: HandleEntity = 1,
        options: UploadOptionsEntity = UploadOptionsEntity()
    ) -> UploadBatchItemEntity {
        UploadBatchItemEntity(
            localFileURL: URL(fileURLWithPath: "/tmp/\(name)"),
            parentHandle: parentHandle,
            isFile: isFile,
            options: options
        )
    }

    private func states(
        of transfers: [CancellableTransferEntity],
        from sut: CancellableUploadTransferUseCase
    ) async -> [CancellableTransferStateEntity] {
        var collected = [CancellableTransferStateEntity]()
        for await state in sut.start(transfers: transfers) {
            collected.append(state)
        }
        return collected
    }

    /// Runs a batch of one item whose SDK callbacks are scripted, and returns everything it reported.
    private func states(
        forSingle name: String,
        isFile: Bool,
        script: MockUploadScript
    ) async -> [CancellableTransferStateEntity] {
        let sdk = MockSdk()
        sdk.stubbedUploadScripts = [name: script]
        return await states(of: [makeTransfer(name, isFile: isFile)], from: makeSUT(sdk))
    }

    /// Everything the batch reported, read from the repository rather than through the use case,
    /// and whatever error ended it.
    private func report(
        of batch: [UploadBatchItemEntity],
        from repository: UploadFileRepository
    ) async -> (events: [TransferEventEntity], error: (any Error)?) {
        var events = [TransferEventEntity]()
        do {
            for try await event in repository.upload(batch: batch) {
                events.append(event)
            }
        } catch {
            return (events, error)
        }
        return (events, nil)
    }

    /// The start reports in `events`: the folder updates that say the batch has started transferring.
    private func startReports(in events: [TransferEventEntity]) -> [FolderTransferUpdateEntity] {
        events.compactMap {
            guard case let .folderUpdate(update) = $0, update.stage == .transferringFiles else { return nil }
            return update
        }
    }

    /// How many of the batch's cancel tokens have been cancelled, waiting for `expected` of them.
    ///
    /// `ThreadSafeCancelToken.cancel()` hops onto a serial queue of its own, so the flag lands a
    /// moment after the call returns rather than inside it.
    private func cancelledUploadTokenCount(of sdk: MockSdk, reaching expected: Int) async -> Int {
        for _ in 0..<2000 {
            let count = sdk.startedUploadCancelTokens.filter(\.isCancelled).count
            if count >= expected { return count }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        return sdk.startedUploadCancelTokens.filter(\.isCancelled).count
    }

    /// The value `task` produced, or `nil` if it produced none within `timeout`.
    ///
    /// A batch that never reports itself started never ends, so a test that expects it to be reported
    /// has to be able to give up on it rather than hang waiting.
    private func value<Success: Sendable>(
        of task: Task<Success, Never>,
        within timeout: Duration = .milliseconds(500)
    ) async -> Success? {
        await withTaskGroup(of: Success?.self) { group in
            group.addTask { await task.value }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            // Ends the batch, so that the child still waiting on it has something to wait for.
            task.cancel()
            group.cancelAll()
            return first
        }
    }

    /// A batch whose every item waits for the test to fire its callbacks.
    ///
    /// Handed back in pieces rather than as a started sequence, because `MEGASwift` is not a
    /// dependency of this test target and the erased sequence type cannot be named here.
    private func makeDrivenBatch(
        _ items: [(name: String, isFile: Bool)]
    ) -> (sdk: MockSdk, sut: CancellableUploadTransferUseCase, transfers: [CancellableTransferEntity]) {
        let sdk = MockSdk()
        sdk.stubbedUploadScripts = Dictionary(uniqueKeysWithValues: items.map { ($0.name, MockUploadScript.driven) })
        return (sdk, makeSUT(sdk), items.map { makeTransfer($0.name, isFile: $0.isFile) })
    }

    // MARK: - A single file item

    @Test("A file has started as soon as its transfer starts")
    func aFileHasStartedWhenItsTransferStarts() async {
        let states = await states(forSingle: "photo.jpg", isFile: true, script: .events([.start()]))

        #expect(states == [.transferringFiles])
    }

    @Test("A file whose transfer throws reports failed")
    func aFileThatThrowsReportsFailed() async {
        let states = await states(forSingle: "photo.jpg", isFile: true, script: .failure(.apiEFailed))

        #expect(states == [.failed])
    }

    @Test("A file's byte progress is enough for it to count as started")
    func aFilesByteProgressIsEnoughToCountAsStarted() async {
        // Bytes only move once the transfer is under way, whatever the start callback did.
        let states = await states(forSingle: "photo.jpg", isFile: true, script: .events([.update()]))

        #expect(states == [.transferringFiles])
    }

    @Test("A file reporting nothing but its finish is treated as started")
    func aSilentFileIsTreatedAsStarted() async {
        let states = await states(forSingle: "photo.jpg", isFile: true, script: .silent)

        #expect(states == [.transferringFiles])
    }

    // MARK: - A single folder item

    @Test("A folder's start event is not enough for it to count as started")
    func aFoldersStartEventIsNotEnoughToCountAsStarted() async throws {
        // `start` fires for the virtual transfer the SDK creates for a folder, before it has
        // scanned anything. Taken as a start of the batch, it would call itself started with
        // nothing queued at all.
        let (sdk, sut, transfers) = makeDrivenBatch([("Docs", false)])
        var iterator = sut.start(transfers: transfers).makeAsyncIterator()
        let docs = try await sdk.drivenUploadDelegate(for: "Docs")

        docs.fireStart(fileName: "Docs", isFolderTransfer: true)
        docs.fireFolderUpdate(stage: .scan, name: "Docs", folderCount: 1, fileCount: 2)
        docs.fireFolderUpdate(stage: .createTree, folderCount: 1, createdFolderCount: 1, fileCount: 2)

        // Nothing so far says the folder has started, so the only state the batch ever reaches is the
        // one its transferring stage brings.
        docs.fireFolderUpdate(stage: .transferringFiles, fileCount: 2)
        #expect(await iterator.next() == .transferringFiles)
    }

    @Test("A folder's byte progress before it has scanned is not enough for it to count as started")
    func aFoldersUpdateBeforeScanningIsNotEnoughToCountAsStarted() async {
        // The reported bug: `onTransferUpdate` fires on a folder's virtual transfer while it is
        // still scanning. Read as a start of the batch, it called itself started before the folder
        // had queued a single file.
        let (sdk, sut, transfers) = makeDrivenBatch([("Docs", false)])
        let collector = Task { await states(of: transfers, from: sut) }
        guard let docs = try? await sdk.drivenUploadDelegate(for: "Docs") else {
            Issue.record("the folder was never handed to the SDK")
            return
        }

        docs.fireStart(fileName: "Docs", isFolderTransfer: true)
        docs.fireUpdate(fileName: "Docs")
        docs.fireFinish(fileName: "Docs")

        // Only the finish makes it count as started: nothing before it did.
        #expect(await collector.value == [.transferringFiles])
    }

    @Test("A folder's byte progress once it is transferring is enough for it to count as started")
    func aFoldersUpdateWhileTransferringIsEnoughToCountAsStarted() async throws {
        // A folder's byte updates carry its stage, so one taken while it transfers says the same
        // thing its folder update would have.
        let (sdk, sut, transfers) = makeDrivenBatch([("Docs", false)])
        var iterator = sut.start(transfers: transfers).makeAsyncIterator()
        let docs = try await sdk.drivenUploadDelegate(for: "Docs")

        docs.fireUpdate(fileName: "Docs", stage: .transferringFiles)

        #expect(await iterator.next() == .transferringFiles)
    }

    @Test("A folder has started once it reports reaching its transferring stage")
    func aFolderHasStartedWhenItReportsTransferring() async {
        let states = await states(
            forSingle: "Docs",
            isFile: false,
            script: .events([
                .start(isFolderTransfer: true),
                .folderUpdate(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3),
                .folderUpdate(stage: .createTree, folderCount: 2, createdFolderCount: 1, fileCount: 3),
                .folderUpdate(stage: .transferringFiles, folderCount: 2, createdFolderCount: 2, fileCount: 3)
            ])
        )

        #expect(states == [.transferringFiles])
    }

    @Test("A folder whose transfer throws reports failed")
    func aFolderThatThrowsReportsFailed() async {
        let states = await states(forSingle: "Docs", isFile: false, script: .failure(.apiEFailed))

        #expect(states == [.failed])
    }

    @Test("A folder whose events run out after scanning is treated as started")
    func aFolderWhoseEventsRunOutAfterScanningIsTreatedAsStarted() async {
        // The transfer finishes without ever reaching the transferring stage. Nothing is pending on
        // the folder any more, so it must not hold the batch back forever.
        let states = await states(
            forSingle: "Docs",
            isFile: false,
            script: .events([.folderUpdate(stage: .scan, name: "Docs", folderCount: 2, fileCount: 1)])
        )

        #expect(states == [.transferringFiles])
    }

    @Test("A folder that goes on reporting bytes after it started does not hold the batch back")
    func aFolderReportingBytesAfterItStartedDoesNotHoldTheBatchBack() async throws {
        // A folder's own virtual transfer keeps reporting bytes once its files are moving, and
        // those updates carry no stage. Taken as the folder's whole standing rather than as one
        // more snapshot of it, the folder would stop counting as started and the batch would go
        // unreported until the folder had uploaded -- minutes, for a folder worth batching.
        let (sdk, sut, transfers) = makeDrivenBatch([("Docs", false), ("Pics", false)])
        let collector = Task { await self.states(of: transfers, from: sut) }
        let docs = try await sdk.drivenUploadDelegate(for: "Docs")
        let pics = try await sdk.drivenUploadDelegate(for: "Pics")

        docs.fireFolderUpdate(stage: .transferringFiles, name: "Docs", fileCount: 1)
        docs.fireUpdate(fileName: "Docs")
        pics.fireFolderUpdate(stage: .transferringFiles, name: "Pics", fileCount: 1)

        // Neither folder has finished, and neither needs to: the batch has started because both have.
        #expect(await value(of: collector) == [.transferringFiles])
    }

    // MARK: - The batch as a whole

    @Test("An empty batch fails, as the SDK answers one with EARGS")
    func anEmptyBatchFails() async {
        let states = await states(of: [], from: makeSUT(MockSdk()))

        #expect(states == [.failed])
    }

    @Test("Every item of the batch is handed to the SDK")
    func everyItemIsHandedToTheSdk() async {
        let sdk = MockSdk()
        sdk.defaultUploadScript = .silent
        let transfers = [
            makeTransfer("a.jpg", isFile: true),
            makeTransfer("b.jpg", isFile: true),
            makeTransfer("Docs", isFile: false)
        ]

        _ = await states(of: transfers, from: makeSUT(sdk))

        #expect(Set(sdk.startedUploadPaths.map { ($0 as NSString).lastPathComponent })
                == ["a.jpg", "b.jpg", "Docs"])
    }

    @Test("Every item is handed to the SDK with its own parent and its own options")
    func everyItemKeepsItsOwnParentAndOptions() async {
        // A batch may span several destinations, and each item carries how it is to be queued, so
        // neither may be taken from the batch's first item and applied to the rest.
        let sdk = MockSdk()
        sdk.defaultUploadScript = .silent
        let batch = [
            makeItem("a.jpg", isFile: true, parentHandle: 7, options: UploadOptionsEntity(appData: "a", startFirst: true)),
            makeItem("Docs", isFile: false, parentHandle: 8, options: UploadOptionsEntity(appData: "docs"))
        ]

        _ = await report(of: batch, from: UploadFileRepository(sdk: sdk))

        let started = zip(
            sdk.startedUploadPaths.map { ($0 as NSString).lastPathComponent },
            zip(sdk.startedUploadParentHandles, sdk.startedUploadOptions)
        )
        let byName = Dictionary(uniqueKeysWithValues: started.map { ($0.0, $0.1) })
        #expect(byName["a.jpg"]?.0 == 7)
        #expect(byName["a.jpg"]?.1.appData == "a")
        #expect(byName["a.jpg"]?.1.startFirst == true)
        #expect(byName["Docs"]?.0 == 8)
        #expect(byName["Docs"]?.1.appData == "docs")
        #expect(byName["Docs"]?.1.startFirst == false)
    }

    @Test("A batch where every item fails reports failed, and never says it started first")
    func aBatchWhereEveryItemFailsReportsFailed() async {
        // A failed item has nothing left pending on it, which is the same thing having started
        // means, so a wholly failed batch satisfies the started check too. Read in that order it
        // would report itself started and only then throw, and a screen would call it a success.
        let sdk = MockSdk()
        sdk.defaultUploadScript = .failure(.apiEFailed)
        let transfers = [makeTransfer("a.jpg", isFile: true), makeTransfer("b.jpg", isFile: true)]

        let states = await states(of: transfers, from: makeSUT(sdk))

        #expect(states == [.failed])
    }

    @Test("A batch where one item starts reports transferring files")
    func aBatchWhereOneItemStartsReportsTransferringFiles() async {
        // No partial failure state exists: what happens to the rest shows in the transfers widget,
        // so one item starting is enough.
        let sdk = MockSdk()
        sdk.stubbedUploadScripts = [
            "a.jpg": .failure(.apiEFailed),
            "b.jpg": .events([.start()])
        ]
        let transfers = [makeTransfer("a.jpg", isFile: true), makeTransfer("b.jpg", isFile: true)]

        let states = await states(of: transfers, from: makeSUT(sdk))

        #expect(states == [.transferringFiles])
    }

    @Test("The batch only reports started once every item has")
    func theBatchOnlyReportsStartedOnceEveryItemHas() async throws {
        let (sdk, sut, transfers) = makeDrivenBatch([("photo.jpg", true), ("Docs", false)])
        var iterator = sut.start(transfers: transfers).makeAsyncIterator()
        let photo = try await sdk.drivenUploadDelegate(for: "photo.jpg")
        let docs = try await sdk.drivenUploadDelegate(for: "Docs")

        // The file has started, but Docs is still scanning, so nothing may be reported yet.
        photo.fireStart(fileName: "photo.jpg")
        docs.fireFolderUpdate(stage: .scan, name: "Docs", folderCount: 1, fileCount: 2)

        docs.fireFolderUpdate(stage: .transferringFiles, fileCount: 2)
        #expect(await iterator.next() == .transferringFiles)
        #expect(await iterator.next() == nil)
    }

    @Test("A folder is handed to the SDK without waiting for the files of the batch to start")
    func aFolderIsHandedToTheSdkWithoutWaitingForFiles() async throws {
        // Files and folders go together. Queued behind the files, the folder below would not reach
        // the SDK at all, because the file before it never starts.
        let (sdk, sut, transfers) = makeDrivenBatch([("photo.jpg", true), ("Docs", false)])
        var iterator = sut.start(transfers: transfers).makeAsyncIterator()
        let docs = try await sdk.drivenUploadDelegate(for: "Docs")

        #expect(sdk.startedUploadPaths.map { ($0 as NSString).lastPathComponent }.contains("Docs"))

        // Left running, the iterator would keep the batch alive past the end of the test.
        docs.fireFinish(fileName: "Docs")
        try await sdk.drivenUploadDelegate(for: "photo.jpg").fireFinish(fileName: "photo.jpg")
        #expect(await iterator.next() == .transferringFiles)
    }

    // MARK: - Keeping the items apart

    @Test("Two items sharing a file name in different parents are folded apart")
    func twoItemsSharingAFileNameAreFoldedApart() async throws {
        // A real selection: the same folder name under two different parents. Were the fold keyed
        // by name rather than by the item's place in the batch, one would overwrite the other and
        // the batch would call itself started with an item still scanning.
        let sdk = MockSdk()
        sdk.stubbedUploadScripts = ["/tmp/a/Docs": .driven, "/tmp/b/Docs": .driven]
        let transfers = [makeTransfer("a/Docs", isFile: false), makeTransfer("b/Docs", isFile: false)]
        var iterator = makeSUT(sdk).start(transfers: transfers).makeAsyncIterator()
        let a = try await sdk.drivenUploadDelegate(for: "/tmp/a/Docs")
        let b = try await sdk.drivenUploadDelegate(for: "/tmp/b/Docs")

        a.fireFolderUpdate(stage: .transferringFiles, name: "Docs", fileCount: 1)
        b.fireFolderUpdate(stage: .transferringFiles, name: "Docs", fileCount: 1)

        #expect(await iterator.next() == .transferringFiles)
    }

    // MARK: - Reading the batch's own report
    //
    // Read through the repository rather than the use case, because what is asserted here is what
    // the use case throws away: the transfer the batch is reported as, and which error ended it.

    @Test("The batch is reported as one transfer, started up front and finished at the end")
    func theBatchIsReportedAsOneTransfer() async throws {
        let sdk = MockSdk()
        sdk.defaultUploadScript = .silent
        let batch = [makeItem("a.jpg", isFile: true), makeItem("b.jpg", isFile: true)]

        var events = [TransferEventEntity]()
        for try await event in UploadFileRepository(sdk: sdk).upload(batch: batch) {
            events.append(event)
        }

        guard case .start = events.first else {
            Issue.record("expected the batch to start with its own transfer, got \(String(describing: events.first))")
            return
        }
        guard case .finish = events.last else {
            Issue.record("expected the batch to end with its own transfer, got \(String(describing: events.last))")
            return
        }
        let startReports = events.filter {
            guard case let .folderUpdate(update) = $0 else { return false }
            return update.stage == .transferringFiles
        }
        #expect(startReports.count == 1)
    }

    @Test("The batch is reported as a folder transfer of its own, carrying no counts")
    func theBatchIsReportedAsAFolderTransferWithoutCounts() async {
        // The batch stands in for the virtual transfer the SDK folds a download batch into, and a
        // screen reads it as a folder transfer. It carries no counts of its own: the items scan at
        // overlapping times, so no count taken across them describes the batch.
        let sdk = MockSdk()
        sdk.defaultUploadScript = .silent
        let batch = [makeItem("a.jpg", isFile: true), makeItem("Docs", isFile: false)]

        let batchReport = await report(of: batch, from: UploadFileRepository(sdk: sdk))

        guard case let .start(transfer) = batchReport.events.first else {
            Issue.record("expected the batch to start with its own transfer, got \(String(describing: batchReport.events.first))")
            return
        }
        #expect(transfer.type == .upload)
        #expect(transfer.isFolderTransfer)
        #expect(transfer.totalBytes == 0)
        #expect(transfer.transferredBytes == 0)

        let startReport = startReports(in: batchReport.events).first
        #expect(startReport?.folderCount == 0)
        #expect(startReport?.createdFolderCount == 0)
        #expect(startReport?.fileCount == 0)
    }

    @Test("The batch says it started once, however much its items go on reporting")
    func theStartIsReportedOnlyOnce() async throws {
        // Every callback of every item is folded, and all of them satisfy the started check once
        // the last item has started. Reported each time, a screen would be told the batch had
        // started once per callback of a selection that may run to thousands of them.
        let sdk = MockSdk()
        sdk.defaultUploadScript = .driven
        let batch = [makeItem("a.jpg", isFile: true), makeItem("b.jpg", isFile: true)]
        let running = Task { await self.report(of: batch, from: UploadFileRepository(sdk: sdk)) }
        let a = try await sdk.drivenUploadDelegate(for: "a.jpg")
        let b = try await sdk.drivenUploadDelegate(for: "b.jpg")

        a.fireStart(fileName: "a.jpg")
        b.fireStart(fileName: "b.jpg")
        a.fireUpdate(fileName: "a.jpg")
        b.fireUpdate(fileName: "b.jpg")
        a.fireFinish(fileName: "a.jpg")
        b.fireFinish(fileName: "b.jpg")

        let batchReport = await running.value
        let events = batchReport.events
        #expect(startReports(in: events).count == 1)
        // Its own start, the one start report and its own finish: nothing an item reported is passed on.
        #expect(events.count == 3)
        #expect(batchReport.error == nil)
    }

    @Test("An item lost after the batch started does not fail the batch")
    func anItemFailingAfterTheBatchStartedDoesNotFailTheBatch() async throws {
        // What happens to any one item afterwards shows in the transfers widget. The batch had
        // started, so it finishes, and the screen that asked for it is not sent back to failed.
        let sdk = MockSdk()
        sdk.defaultUploadScript = .driven
        let batch = [makeItem("a.jpg", isFile: true), makeItem("b.jpg", isFile: true)]
        let running = Task { await self.report(of: batch, from: UploadFileRepository(sdk: sdk)) }
        let a = try await sdk.drivenUploadDelegate(for: "a.jpg")
        let b = try await sdk.drivenUploadDelegate(for: "b.jpg")

        a.fireStart(fileName: "a.jpg")
        b.fireStart(fileName: "b.jpg")
        a.fireFinish(fileName: "a.jpg", errorType: .apiEFailed)
        b.fireFinish(fileName: "b.jpg")

        let batchReport = await running.value
        #expect(batchReport.error == nil)
        #expect(startReports(in: batchReport.events).count == 1)
        guard case .finish = batchReport.events.last else {
            Issue.record("expected the batch to end with its own transfer, got \(String(describing: batchReport.events.last))")
            return
        }
    }

    @Test("A batch that loses every item after starting throws, without walking the start back")
    func aBatchThatLosesEveryItemAfterStartingThrows() async throws {
        // Losing every item is an error whenever it happens, and it is thrown whenever it happens.
        // Reported after the start it changes nothing on the screen, which stopped reading at the
        // start -- what it does is keep the batch from being reported as finished.
        let sdk = MockSdk()
        sdk.defaultUploadScript = .driven
        let batch = [makeItem("a.jpg", isFile: true), makeItem("b.jpg", isFile: true)]
        let running = Task { await self.report(of: batch, from: UploadFileRepository(sdk: sdk)) }
        let a = try await sdk.drivenUploadDelegate(for: "a.jpg")
        let b = try await sdk.drivenUploadDelegate(for: "b.jpg")

        a.fireStart(fileName: "a.jpg")
        b.fireStart(fileName: "b.jpg")
        a.fireFinish(fileName: "a.jpg", errorType: .apiEFailed)
        b.fireFinish(fileName: "b.jpg", errorType: .apiEIncomplete, state: .cancelled)

        let batchReport = await running.value
        #expect(batchReport.error as? TransferErrorEntity == .upload)
        #expect(startReports(in: batchReport.events).count == 1)
        // Thrown instead of finished: a batch with nothing left of it did not end well.
        if case .finish = batchReport.events.last {
            Issue.record("expected the batch not to report itself finished")
        }
    }

    @Test("A wholly failed batch reports the first item's error")
    func aWhollyFailedBatchReportsTheFirstItemsError() async {
        let sdk = MockSdk()
        sdk.stubbedUploadScripts = [
            "a.jpg": .failure(.apiEIncomplete, state: .cancelled),
            "b.jpg": .failure(.apiEFailed)
        ]
        let batch = [makeItem("a.jpg", isFile: true), makeItem("b.jpg", isFile: true)]

        var thrown: (any Error)?
        var events = [TransferEventEntity]()
        do {
            for try await event in UploadFileRepository(sdk: sdk).upload(batch: batch) {
                events.append(event)
            }
        } catch {
            thrown = error
        }

        // The batch's own start is all it ever reported: it never reported itself started.
        #expect(events.count == 1)
        #expect(thrown as? TransferErrorEntity == .cancelled)
    }

    @Test("An empty batch is refused rather than handed to the SDK")
    func anEmptyBatchIsRefused() async {
        let sdk = MockSdk()

        var thrown: (any Error)?
        do {
            for try await _ in UploadFileRepository(sdk: sdk).upload(batch: []) {}
        } catch {
            thrown = error
        }

        #expect(thrown as? TransferErrorEntity == .upload)
        #expect(sdk.startedUploadPaths.isEmpty)
    }

    // MARK: - Cancelling

    @Test("Cancelling the batch cancels every item and reports failed")
    func cancellingTheBatchReportsFailed() async throws {
        let (sdk, sut, transfers) = makeDrivenBatch([("a.jpg", true), ("b.jpg", true)])
        var iterator = sut.start(transfers: transfers).makeAsyncIterator()
        let a = try await sdk.drivenUploadDelegate(for: "a.jpg")
        let b = try await sdk.drivenUploadDelegate(for: "b.jpg")

        sut.cancel()

        // One token is shared by every item of the batch, which is how one call cancels them all.
        let cancelledCount = await cancelledUploadTokenCount(of: sdk, reaching: transfers.count)
        #expect(cancelledCount == transfers.count)

        // The SDK answers a cancelled transfer with a finish whose transfer reads `.cancelled`.
        a.fireFinish(fileName: "a.jpg", errorType: .apiEIncomplete, state: .cancelled)
        b.fireFinish(fileName: "b.jpg", errorType: .apiEIncomplete, state: .cancelled)

        // Nothing started, so the batch as a whole failed. A cancelled batch is not told apart
        // from a failed one: there is no state for it.
        #expect(await iterator.next() == .failed)
        #expect(await iterator.next() == nil)
    }

    @Test("A reader that stops early ends the batch")
    func stopsReadingWhenTheReaderDoes() async throws {
        let sdk = MockSdk()
        sdk.defaultUploadScript = .silent
        let batch = [makeItem("a.jpg", isFile: true), makeItem("b.jpg", isFile: true)]

        var events = [TransferEventEntity]()
        for try await event in UploadFileRepository(sdk: sdk).upload(batch: batch) {
            events.append(event)
            break
        }

        // The batch's own start is all that was read, and stopping there ended it: the items are
        // one live subscription each, held open for as long as they transfer, so dropping the
        // batch has to take them with it rather than leave them reporting into nothing.
        #expect(events.count == 1)
    }

    // MARK: - Under concurrency

    @Test("Events fired from concurrent threads are folded without losing any")
    func concurrentEventsAreFoldedWithoutLoss() async throws {
        // Every other driven test fires from the test's own thread. The SDK fires from its worker
        // threads, and the fold keeps its accumulator unsynchronised on the assumption that merging
        // the items into one channel serialises them.
        let (sdk, sut, transfers) = makeDrivenBatch([("Docs", false), ("Pics", false)])
        let collector = Task { await states(of: transfers, from: sut) }

        // Each item is fired from a task of its own, and reads its delegate there rather than
        // being handed one: a transfer delegate is not `Sendable`, and the SDK never passes one
        // between threads either.
        await withTaskGroup(of: Void.self) { group in
            for name in ["Docs", "Pics"] {
                group.addTask {
                    guard let delegate = try? await sdk.drivenUploadDelegate(for: name) else { return }
                    for _ in 0..<Self.concurrentEventCount {
                        delegate.fireFolderUpdate(stage: .scan, name: name, folderCount: 1, fileCount: 1)
                    }
                }
            }
            await group.waitForAll()
        }

        try await sdk.drivenUploadDelegate(for: "Docs").fireFinish(fileName: "Docs")
        try await sdk.drivenUploadDelegate(for: "Pics").fireFinish(fileName: "Pics")

        // A hundred scans said nothing about the batch, and the two finishes reported it started
        // exactly once -- no event folded twice, and none lost.
        #expect(await collector.value == [.transferringFiles])
    }

    private static let concurrentEventCount = 50
}
