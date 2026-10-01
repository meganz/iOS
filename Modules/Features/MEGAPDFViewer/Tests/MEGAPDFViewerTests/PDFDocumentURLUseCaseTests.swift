import Foundation
import MEGADomain
import MEGADomainMock
@testable import MEGAPDFViewer
import MEGASwift
import Testing

private struct MockPendingDownloadNodeUseCase: DownloadNodeUseCaseProtocol {
    let transferEvents: AsyncStream<TransferEventEntity>

    func downloadFileToTempFolder(node: NodeEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        transferEvents.eraseToAnyAsyncSequence()
    }

    func downloadFileToOffline(
        forNodeHandle handle: HandleEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        transferEvents.eraseToAnyAsyncSequence()
    }

    func downloadFileToOffline(
        _ node: NodeEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        transferEvents.eraseToAnyAsyncSequence()
    }

    func downloadChatFileToOffline(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity> {
        transferEvents.eraseToAnyAsyncSequence()
    }

    func downloadFileLinkToOffline(
        _ fileLink: FileLinkEntity,
        filename: String?,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity> {
        transferEvents.eraseToAnyAsyncSequence()
    }

    func cancelDownloadTransfers() {}
}

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

    @Test func node_finishWithErrorAndPath_throwsTransferFailed() async {
        let transfer = TransferEntity(
            path: "/tmp/downloaded.pdf",
            lastErrorExtended: .generic
        )
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(result: .success(transfer)))

        await #expect(throws: PDFDocumentLoadError.transferFailed) {
            for try await _ in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {}
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func node_transferEventsEndWithoutFinish_throwsTransferFailed() async {
        let transfer = TransferEntity(transferredBytes: 40, totalBytes: 100, path: nil)
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(transferEvents: [.update(transfer)]))

        await #expect(throws: PDFDocumentLoadError.transferFailed) {
            for try await _ in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {}
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func node_consumerCancelled_terminatesTransferEvents() async {
        let (transferEvents, transferContinuation) = AsyncStream.makeStream(of: TransferEventEntity.self)
        let (terminations, terminationContinuation) = AsyncStream.makeStream(of: Void.self)
        transferContinuation.onTermination = { _ in
            terminationContinuation.yield()
            terminationContinuation.finish()
        }
        let sut = PDFDocumentURLUseCase(
            downloadUseCase: MockPendingDownloadNodeUseCase(transferEvents: transferEvents)
        )

        let task = Task {
            for try await _ in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {}
        }
        task.cancel()

        var iterator = terminations.makeAsyncIterator()
        #expect(await iterator.next() != nil)
    }

    @Test func node_downloadThrows_throwsTransferFailed() async {
        let sut = PDFDocumentURLUseCase(downloadUseCase: MockDownloadNodeUseCase(result: .failure(.generic)))

        await #expect(throws: PDFDocumentLoadError.transferFailed) {
            for try await _ in sut.localDocumentURL(for: .node(NodeEntity(handle: 1))) {}
        }
    }
}
