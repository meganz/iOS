import Foundation
@testable import MEGA
import MEGAAppPresentationMock
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("PDFViewerRevampRouter.canOpen")
struct PDFViewerRevampRouterCanOpenTests {
    @Test(
        "a pdf extension in any case is opened with the remote flag on",
        arguments: ["a.pdf", "a.PDF", "a.Pdf", "/path/to/Report.pdf"]
    )
    func pdfExtension_remoteFlagOn_isOpened(fileName: String) {
        #expect(canOpen(fileName: fileName, isLocalFlagOn: false, isRemoteFlagOn: true))
    }

    @Test("a pdf is opened with the local flag on")
    func pdfExtension_localFlagOn_isOpened() {
        #expect(canOpen(fileName: "a.pdf", isLocalFlagOn: true, isRemoteFlagOn: false))
    }

    @Test("a pdf is opened with both flags on")
    func pdfExtension_bothFlagsOn_isOpened() {
        #expect(canOpen(fileName: "a.pdf", isLocalFlagOn: true, isRemoteFlagOn: true))
    }

    @Test("a pdf is not opened with both flags off")
    func pdfExtension_bothFlagsOff_isNotOpened() {
        #expect(!canOpen(fileName: "a.pdf", isLocalFlagOn: false, isRemoteFlagOn: false))
    }

    @Test(
        "anything that does not end in a pdf extension is not opened",
        arguments: ["a.pdf.txt", "pdf", "a.pdfx", "a", ""]
    )
    func otherExtension_flagsOn_isNotOpened(fileName: String) {
        #expect(!canOpen(fileName: fileName, isLocalFlagOn: true, isRemoteFlagOn: true))
    }

    private func canOpen(fileName: String, isLocalFlagOn: Bool, isRemoteFlagOn: Bool) -> Bool {
        PDFViewerRevampRouter.canOpen(
            fileName: fileName,
            featureFlagProvider: MockFeatureFlagProvider(list: [.pdfPreviewRevamp: isLocalFlagOn]),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosPdfPreviewRevamp: isRemoteFlagOn])
        )
    }
}

@Suite("PDFViewerRevampRouter.makeDownloadFileRepository")
struct PDFViewerRevampRouterDownloadFileRepositoryTests {
    private static let node = MockNode(handle: 5, nodeBase64Handle: "BQAAAAAA", name: "attachment.pdf")

    @Test("a temp folder download finishes with the node no SDK tree has")
    func tempFolderDownload_nodeOutsideAnyTree_isDownloaded() async throws {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: destination) }
        let sut = PDFViewerRevampRouter.makeDownloadFileRepository(
            node: Self.node,
            sdk: MockSdk(nodes: [])
        )

        var downloadedNodeHandle: HandleEntity?
        for await event in try sut.downloadTo(destination, nodeHandle: Self.node.handle, appData: nil) {
            if case .finish(let transfer) = event {
                downloadedNodeHandle = transfer.nodeHandle
            }
        }

        #expect(downloadedNodeHandle == Self.node.handle)
    }

    @Test("a batch download starts the node no SDK tree has")
    func batchDownload_nodeOutsideAnyTree_isStarted() async throws {
        let sdk = MockSdk(nodes: [])
        let sut = PDFViewerRevampRouter.makeDownloadFileRepository(node: Self.node, sdk: sdk)
        let item = DownloadBatchItemEntity(
            source: .node(Self.node.handle),
            destination: .folder(FileManager.default.temporaryDirectory),
            appData: nil,
            startFirst: true
        )

        for try await _ in sut.downloadBatchFileItemProgress(item: item) {}

        #expect(sdk.startedDownloadBatches.first?.count == 1)
    }
}
