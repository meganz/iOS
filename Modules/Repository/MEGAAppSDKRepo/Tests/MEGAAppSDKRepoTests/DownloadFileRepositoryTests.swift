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

        return DownloadFileRepository(sdk: sdk, nodeProvider: MockMEGANodeProvider(node: folderNode))
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
        DownloadFileRepository(sdk: MockSdk(nodes: accountNodes), preresolvedNodes: preresolvedNodes)
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
            nodeProvider: MockMEGANodeProvider(node: fileLinkNode)
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
