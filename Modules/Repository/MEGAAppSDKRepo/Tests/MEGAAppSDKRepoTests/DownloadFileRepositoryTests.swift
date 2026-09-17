import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing

/// Covers what a folder download reports back when it does not complete, since the counts are all the
/// caller has to tell a partial download from one that never started.
@Suite("DownloadFileRepository folder downloads")
struct DownloadFileRepositoryTests {
    private static let folderNode = MockNode(handle: 1, name: "MyFolder", nodeType: .folder)
    private static let destination = URL(fileURLWithPath: "/tmp/MyFolder")

    private static func makeSUT(
        fileCount: Int,
        folderUpdates: [(stage: MEGATransferStage, fileCount: UInt)]
    ) -> DownloadFileRepository {
        let sdk = MockSdk(nodes: [folderNode], folderInfo: MockFolderInfo(files: fileCount))
        sdk.stubbedDownloadTransferResult = .failure(MockError(errorType: .apiEWrite))
        sdk.stubbedFolderTransferUpdates = folderUpdates

        return DownloadFileRepository(sdk: sdk, nodeProvider: MockMEGANodeProvider(node: folderNode), chatNodeProvider: MockChatMEGANodeProvider())
    }

    /// The transfer only reports the size of the tree once it starts building the local one, so a failure
    /// before that leaves the tally with nothing to report a shortfall against.
    @Test("a folder that failed before reporting a stage is counted from the node instead")
    func failedBeforeAnyStage_countsFromTheNode() async throws {
        let sut = Self.makeSUT(fileCount: 100, folderUpdates: [])

        let result = try await sut.downloadFolder(nodeHandle: Self.folderNode.handle, to: Self.destination, metaData: nil)

        #expect(result.isSuccess == false)
        #expect(result.fileCount == 100, "All hundred of the folder's files are missing, not one folder.")
        #expect(result.downloadedFileCount == 0)
    }

    @Test("a folder that reported its tree keeps that count rather than asking the node again")
    func failedAfterTreeStage_keepsTheReportedCount() async throws {
        let sut = Self.makeSUT(
            fileCount: 100,
            folderUpdates: [(stage: .createTree, fileCount: 40)]
        )

        let result = try await sut.downloadFolder(nodeHandle: Self.folderNode.handle, to: Self.destination, metaData: nil)

        #expect(
            result.fileCount == 40,
            "What the transfer walked is what was going to be downloaded, even where the node holds more."
        )
    }
}

/// Covers where `downloadFile` finds the node it is asked for. It cannot suspend to look one up, so a
/// source that is in no SDK tree -- a public album link's photos -- has to hand its nodes over resolved.
@Suite("DownloadFileRepository node resolution")
struct DownloadFileRepositoryNodeResolutionTests {
    private static let photoNode = MockNode(handle: 5, name: "photo.jpg")
    private static let destination = URL(fileURLWithPath: "/tmp/Documents")

    private static func makeSUT(
        accountNodes: [MEGANode] = [],
        preresolvedNodes: [HandleEntity: MEGANode] = [:]
    ) -> DownloadFileRepository {
        DownloadFileRepository(sdk: MockSdk(nodes: accountNodes), chatNodeProvider: MockChatMEGANodeProvider(), preresolvedNodes: preresolvedNodes)
    }

    @Test("a node that is only in the resolved nodes is downloaded rather than looked up")
    func preresolvedNode_isDownloaded() async {
        let sut = Self.makeSUT(preresolvedNodes: [Self.photoNode.handle: Self.photoNode])

        let downloadedNodeHandle = await Self.download(Self.photoNode.handle, with: sut)

        #expect(downloadedNodeHandle == Self.photoNode.handle)
    }

    @Test("a node in the account tree is still downloaded when nothing was resolved up front")
    func accountNode_isDownloaded() async {
        let sut = Self.makeSUT(accountNodes: [Self.photoNode])

        let downloadedNodeHandle = await Self.download(Self.photoNode.handle, with: sut)

        #expect(downloadedNodeHandle == Self.photoNode.handle)
    }

    @Test("a node in neither the resolved nodes nor the account tree fails before any transfer starts")
    func unresolvableNode_throws() {
        let sut = Self.makeSUT()

        #expect(throws: TransferErrorEntity.couldNotFindNodeByHandle) {
            _ = try sut.downloadFile(
                forNodeHandle: Self.photoNode.handle,
                to: Self.destination,
                filename: nil,
                appdata: nil,
                startFirst: false
            )
        }
    }

    /// The handle the finished transfer carries, which is what says which node the SDK was handed.
    private static func download(
        _ handle: HandleEntity,
        with sut: DownloadFileRepository
    ) async -> HandleEntity? {
        guard let stream = try? sut.downloadFile(
            forNodeHandle: handle,
            to: destination,
            filename: nil,
            appdata: nil,
            startFirst: false
        ) else {
            return nil
        }

        for await event in stream {
            if case .finish(let transfer) = event {
                return transfer.nodeHandle
            }
        }
        return nil
    }
}

/// Covers the file link download reporting back at all. The transfer delegate is the only thing that ends
/// this stream, so without it a caller iterating the sequence waits on a download that is running fine.
@Suite("DownloadFileRepository file link downloads")
struct DownloadFileRepositoryFileLinkTests {
    private static let fileNode = MockNode(handle: 5, name: "photo.jpg")
    private static let fileLink = FileLinkEntity(linkURL: URL(string: "https://mega.nz/file/abcdefgh#key")!)
    private static let destination = URL(fileURLWithPath: "/tmp/Documents")

    private static func makeSUT(fileLinkNode: MEGANode?) -> DownloadFileRepository {
        DownloadFileRepository(
            sdk: MockSdk(fileLinkNode: fileLinkNode),
            nodeProvider: MockMEGANodeProvider(node: fileLinkNode),
            chatNodeProvider: MockChatMEGANodeProvider()
        )
    }

    private static func downloadEvents(from sut: DownloadFileRepository) async throws -> [TransferEventEntity] {
        let stream = try sut.downloadFileLink(
            fileLink,
            named: fileNode.name ?? "",
            to: destination,
            metaData: nil,
            startFirst: false
        )

        return await stream.reduce(into: [TransferEventEntity]()) { $0.append($1) }
    }

    @Test("a link whose node resolves reports the transfer and ends the stream")
    func resolvedLink_reportsTheTransferAndEnds() async throws {
        let sut = Self.makeSUT(fileLinkNode: Self.fileNode)

        let events = try await Self.downloadEvents(from: sut)
        let started = events.contains { if case .start = $0 { true } else { false } }
        let finished = events.contains { if case .finish = $0 { true } else { false } }

        // Reaching the end at all is the point: the stream only terminates once the transfer reports back.
        #expect(started)
        #expect(finished)
    }

    @Test("a link whose node cannot be resolved ends the stream instead of waiting on a transfer")
    func unresolvableLink_endsWithoutATransfer() async throws {
        let sut = Self.makeSUT(fileLinkNode: nil)

        let events = try await Self.downloadEvents(from: sut)

        #expect(events.isEmpty)
    }
}

/// Covers the batch download: what of each item reaches the SDK, and what the awaiting overload --
/// the one a caller with nothing to show for progress uses -- reports back.
@Suite("DownloadFileRepository batch downloads")
struct DownloadFileRepositoryBatchTests {
    private static let photoNode = MockNode(handle: 5, name: "photo.jpg")
    private static let destination = URL(fileURLWithPath: "/tmp/Documents")

    private static func makeSUT(
        transferResult: Result<MockTransfer, MockError>? = nil
    ) -> (sut: DownloadFileRepository, sdk: MockSdk) {
        let sdk = MockSdk(nodes: [photoNode])
        sdk.stubbedDownloadTransferResult = transferResult
        return (
            DownloadFileRepository(
                sdk: sdk,
                nodeProvider: MockMEGANodeProvider(node: photoNode),
                chatNodeProvider: MockChatMEGANodeProvider()
            ),
            sdk
        )
    }

    private static func batchItem(
        destination: DownloadDestinationEntity = .folder(destination),
        appData: String? = nil,
        startFirst: Bool = false
    ) -> DownloadBatchItemEntity {
        DownloadBatchItemEntity(
            source: .node(photoNode.handle),
            destination: destination,
            appData: appData,
            startFirst: startFirst
        )
    }

    @Test("a destination folder reaches the SDK as a folder rather than as a file path")
    func startedBatch_carriesTheFolderAsAFolder() async throws {
        let (sut, sdk) = Self.makeSUT()

        try await sut.download(batch: [Self.batchItem()])

        let item = try #require(sdk.startedDownloadBatches.first?.first)
        // Without the separator the SDK reads the path as the file to write, landing the node in
        // /tmp under the name Documents.
        #expect(item.localPath == "/tmp/Documents/")
        #expect(item.customName == nil, "Nothing was renamed, so the node keeps the name it has on MEGA.")
    }

    @Test("a destination file reaches the SDK as the folder holding it and the name to store it under")
    func startedBatch_carriesTheFileAsAFolderAndName() async throws {
        let (sut, sdk) = Self.makeSUT()

        try await sut.download(
            batch: [Self.batchItem(destination: .file(Self.destination.appendingPathComponent("photo.jpg")))]
        )

        let item = try #require(sdk.startedDownloadBatches.first?.first)
        #expect(item.localPath == "/tmp/Documents/")
        #expect(item.customName == "photo.jpg")
    }

    @Test("what the item was to be tagged and queued as is handed to the SDK with it")
    func startedBatch_carriesTheItemsOptions() async throws {
        let (sut, sdk) = Self.makeSUT()

        try await sut.download(batch: [Self.batchItem(appData: ">SaveInPhotosApp", startFirst: true)])

        let batch = try #require(sdk.startedDownloadBatches.first)
        let item = try #require(batch.first)
        #expect(sdk.startedDownloadBatches.count == 1, "One batch, however many items it holds.")
        #expect(batch.count == 1)
        #expect(item.appData == ">SaveInPhotosApp")
        #expect(item.startFirst)
        #expect(item.undelete == false)
    }

    @Test("every item of one batch is started under the same cancel token")
    func startedBatch_sharesOneCancelToken() async throws {
        let (sut, sdk) = Self.makeSUT()

        try await sut.download(batch: [Self.batchItem(), Self.batchItem()])

        // The batch is cancelled as a whole, which only works while one token covers all of it.
        #expect(sdk.startedDownloadBatchCancelTokens.count == 1)
    }

    @Test("awaiting a batch returns once the transfer has finished")
    func awaitedBatch_returnsOnFinish() async throws {
        let (sut, _) = Self.makeSUT(transferResult: .success(MockTransfer(type: .download)))

        try await sut.download(batch: [Self.batchItem()])
    }

    @Test("awaiting a batch that failed throws rather than returning as if it had finished")
    func awaitedBatch_throwsOnFailure() async {
        let (sut, _) = Self.makeSUT(transferResult: .failure(MockError(errorType: .apiEWrite)))

        await #expect(throws: (any Error).self) {
            try await sut.download(batch: [Self.batchItem()])
        }
    }

    // MARK: - Batch result

    /// What the batch's wrapper transfer reports as its tag, and so what its file transfers carry as
    /// their `folderTransferTag`.
    private static let batchTag = 42
    /// Another batch's tag, for a file transfer that must not be counted into this one.
    private static let otherBatchTag = 99

    private static func makeBatchResultSUT(
        subTransfers: [(transfer: MockTransfer, error: MockError)],
        transferResult: Result<MockTransfer, MockError>? = nil
    ) -> (sut: DownloadFileRepository, sdk: MockSdk) {
        let (sut, sdk) = makeSUT(transferResult: transferResult)
        sdk.stubbedDownloadBatchTag = batchTag
        sdk.stubbedDownloadBatchSubTransfers = subTransfers
        return (sut, sdk)
    }

    /// One file transfer of the batch, whatever item of it the file came from: nothing on a file transfer
    /// names the item, and the counts do not need it to.
    private static func file(
        succeeded: Bool = true,
        folderTransferTag: Int = batchTag
    ) -> (transfer: MockTransfer, error: MockError) {
        (
            MockTransfer(type: .download, folderTransferTag: folderTransferTag, appData: ">exportFile"),
            MockError(errorType: succeeded ? .apiOk : .apiEWrite)
        )
    }

    @Test("every file transfer under the batch is reported, and the successful ones counted")
    func batchResult_reportsEveryFileTransfer() async throws {
        let (sut, _) = Self.makeBatchResultSUT(
            subTransfers: [Self.file(), Self.file(), Self.file(succeeded: false)]
        )

        let result = try await sut.downloadResult(batch: [Self.batchItem()])

        #expect(result == .partiallyFailed(downloadedFileCount: 2, failedFileCount: 1))
    }

    /// Nothing was queued, so nothing of the batch reached the transfer manager and there is no count to
    /// report — only that it did not get anywhere.
    @Test("a batch that ended before queuing a file transfer reports failure")
    func batchResult_abortedBeforeQueuing_reportsFailed() async throws {
        let (sut, _) = Self.makeBatchResultSUT(
            subTransfers: [],
            transferResult: .failure(MockError(errorType: .apiEIncomplete))
        )

        let result = try await sut.downloadResult(batch: [Self.batchItem()])

        #expect(result == .failed)
    }

    /// An empty folder downloads no files at all, and the SDK finishes that batch without error. There is
    /// nothing to count, and nothing missing either.
    @Test("a batch that downloaded no files reports no counts rather than failing")
    func batchResult_noFiles_reportsNothing() async throws {
        let (sut, _) = Self.makeBatchResultSUT(subTransfers: [])

        let result = try await sut.downloadResult(batch: [Self.batchItem()])

        #expect(result == .completed(fileCount: 0))
    }

    /// A batch comes back with an error whether one file inside it failed or none of them ever started, and
    /// only the counts tell those apart — so throwing would discard what did arrive.
    @Test("a batch that came back short reports what arrived rather than throwing")
    func batchResult_failedBatch_reportsWhatArrived() async throws {
        let (sut, _) = Self.makeBatchResultSUT(
            subTransfers: [Self.file(), Self.file(succeeded: false)],
            transferResult: .failure(MockError(errorType: .apiEIncomplete))
        )

        let result = try await sut.downloadResult(batch: [Self.batchItem(), Self.batchItem()])

        #expect(result == .partiallyFailed(downloadedFileCount: 1, failedFileCount: 1))
    }

    /// The item is handed to the SDK exactly as the caller described it: nothing is appended to its tag,
    /// which every reader of those tags matches with `contains`.
    @Test("the item's own tag reaches the SDK untouched")
    func batchResult_keepsTheItemsOwnAppData() async throws {
        let (sut, sdk) = Self.makeBatchResultSUT(subTransfers: [])

        _ = try await sut.downloadResult(batch: [Self.batchItem(appData: ">exportFile")])

        let item = try #require(sdk.startedDownloadBatches.first?.first)
        #expect(item.appData == ">exportFile")
    }

    /// Every download reports to the same globally registered delegates, so a batch is told apart from
    /// whatever else is running only by the tag its own wrapper transfer carries.
    @Test("a file transfer of another batch is not counted into this one")
    func batchResult_ignoresAnotherBatchsFileTransfers() async throws {
        let (sut, _) = Self.makeBatchResultSUT(
            subTransfers: [
                Self.file(),
                Self.file(folderTransferTag: Self.otherBatchTag),
                Self.file(succeeded: false, folderTransferTag: Self.otherBatchTag)
            ]
        )

        let result = try await sut.downloadResult(batch: [Self.batchItem()])

        #expect(result == .completed(fileCount: 1), "Only the one file transfer started under this batch.")
    }

    /// A transfer belonging to no batch at all reports `0`, which must not be read as this batch's tag.
    @Test("a transfer belonging to no batch is not counted into one")
    func batchResult_ignoresTransfersOutsideAnyBatch() async throws {
        let (sut, _) = Self.makeBatchResultSUT(subTransfers: [Self.file(folderTransferTag: 0)])

        let result = try await sut.downloadResult(batch: [Self.batchItem()])

        #expect(result == .completed(fileCount: 0))
    }

    /// A cancelled consumer sees the event stream finish rather than throw, so the counts taken from it
    /// describe a batch that stopped rather than one that completed. Without the check they would be
    /// handed back as `.completed`, telling the caller everything it asked for arrived.
    @Test("a batch whose caller was cancelled throws rather than reporting a completed batch")
    func batchResult_cancelledCaller_throwsRatherThanReportingCompleted() async throws {
        let nodeProvider = ParkingNodeProvider()
        let sut = DownloadFileRepository(
            sdk: MockSdk(),
            nodeProvider: nodeProvider,
            chatNodeProvider: MockChatMEGANodeProvider()
        )

        let batch = Task { try await sut.downloadResult(batch: [Self.batchItem()]) }
        // Waited for rather than assumed: the cancellation has to land on a caller that is already
        // waiting on the batch, which is the case the check is there for.
        var calls = nodeProvider.calls.makeAsyncIterator()
        await calls.next()
        batch.cancel()

        await #expect(throws: CancellationError.self) {
            _ = try await batch.value
        }
    }

    @Test("awaiting a batch whose items resolve to no node still returns rather than hanging")
    func awaitedBatch_withNothingToDownload_returns() async throws {
        let sdk = MockSdk()
        let sut = DownloadFileRepository(
            sdk: sdk,
            nodeProvider: MockMEGANodeProvider(),
            chatNodeProvider: MockChatMEGANodeProvider()
        )

        try await sut.download(batch: [Self.batchItem()])

        #expect(try #require(sdk.startedDownloadBatches.first).isEmpty)
    }
}

/// A node provider that parks instead of answering, so a batch is still being built when the test cancels
/// the caller waiting on it.
private final class ParkingNodeProvider: MEGANodeProviderProtocol, @unchecked Sendable {
    let calls: AsyncStream<Void>

    private let callsContinuation: AsyncStream<Void>.Continuation

    init() {
        (calls, callsContinuation) = AsyncStream.makeStream()
    }

    func node(for handle: HandleEntity) async -> MEGANode? {
        callsContinuation.yield()
        // Only cancellation ends this, which is what the test drives.
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 60)
        return nil
    }
}
