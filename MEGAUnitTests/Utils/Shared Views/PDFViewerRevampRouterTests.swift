import Foundation
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

@Suite("PDFViewerRevampRouter.canOpen")
struct PDFViewerRevampRouterCanOpenTests {
    @Test(
        "a pdf extension in any case is opened with the flag on",
        arguments: ["a.pdf", "a.PDF", "a.Pdf", "/path/to/Report.pdf"]
    )
    func pdfExtension_flagOn_isOpened(fileName: String) {
        #expect(PDFViewerRevampRouter.canOpen(fileName: fileName, isFeatureEnabled: true))
    }

    @Test(
        "anything that does not end in a pdf extension is not opened",
        arguments: ["a.pdf.txt", "pdf", "a.pdfx", "a", ""]
    )
    func otherExtension_flagOn_isNotOpened(fileName: String) {
        #expect(!PDFViewerRevampRouter.canOpen(fileName: fileName, isFeatureEnabled: true))
    }

    @Test("a pdf is not opened with the flag off")
    func pdfExtension_flagOff_isNotOpened() {
        #expect(!PDFViewerRevampRouter.canOpen(fileName: "a.pdf", isFeatureEnabled: false))
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
