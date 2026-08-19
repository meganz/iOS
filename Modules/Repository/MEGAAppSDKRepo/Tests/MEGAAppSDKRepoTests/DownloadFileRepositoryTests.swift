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
