import Foundation
import MEGADomain
import MEGADomainMock
@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFDocumentURLUseCaseTests {
    @Test func local_yieldsSingleReadyEventThenFinishes() async throws {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase())

        var events: [PDFDocumentLoadEvent] = []
        for try await event in sut.localDocumentURL(for: .local(url)) {
            events.append(event)
        }

        #expect(events == [.ready(url)])
    }

    @Test func node_mapsUpdateTransferToProgress() async throws {
        let transfer = TransferEntity(transferredBytes: 40, totalBytes: 100, path: "/tmp/downloaded.pdf")
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(result: .success(transfer)))

        var events: [PDFDocumentLoadEvent] = []
        for try await event in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {
            events.append(event)
        }

        #expect(events == [.progress(0.4), .ready(URL(fileURLWithPath: "/tmp/downloaded.pdf"))])
    }

    @Test func node_updateWithZeroTotalBytes_isNotMappedToProgress() async throws {
        let transfer = TransferEntity(transferredBytes: 0, totalBytes: 0, path: "/tmp/downloaded.pdf")
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(result: .success(transfer)))

        var events: [PDFDocumentLoadEvent] = []
        for try await event in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {
            events.append(event)
        }

        #expect(events == [.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf"))])
    }

    @Test func node_finishWithoutPath_throwsMissingDownloadPath() async {
        let transfer = TransferEntity(transferredBytes: 0, totalBytes: 0, path: nil)
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(result: .success(transfer)))

        await #expect(throws: PDFDocumentLoadError.missingDownloadPath) {
            for try await _ in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {}
        }
    }

    @Test func node_downloadThrows_throwsTransferFailed() async {
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(result: .failure(.generic)))

        await #expect(throws: PDFDocumentLoadError.transferFailed) {
            for try await _ in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {}
        }
    }
}
