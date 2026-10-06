import Foundation
import MEGADomain
import MEGAL10n
@testable import MEGAPDFViewer
import Observation
import PDFKit
import Testing

private final class MockPDFDocumentURLUseCase: PDFDocumentURLUseCaseProtocol {
    private let makeStream: () -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error>
    private(set) var localDocumentURLCallCount = 0

    init(stream: AsyncThrowingStream<PDFDocumentLoadEvent, any Error>) {
        makeStream = { stream }
    }

    init(makeStream: @escaping () -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error>) {
        self.makeStream = makeStream
    }

    func localDocumentURL(for pdfDocumentSource: PDFViewerDocumentSource) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        localDocumentURLCallCount += 1
        return makeStream()
    }
}

private struct MockPDFDocumentLoader: PDFDocumentLoading {
    let document: PDFDocument?

    func loadDocument(url: URL) -> PDFDocument? {
        document
    }
    
    /// A one-page document, so the loader mock can return something real.
    static func makeDocument(pageCount: Int = 1) -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            document.insert(PDFPage(), at: index)
        }
        return document
    }
}

/// Parses the first request only, like a file that disappears between the
/// viewer's parse and the thumbnails' parse.
private final class FirstLoadOnlyPDFDocumentLoader: PDFDocumentLoading {
    private var hasLoaded = false

    func loadDocument(url: URL) -> PDFDocument? {
        guard !hasLoaded else { return nil }
        hasLoaded = true
        return MockPDFDocumentLoader.makeDocument()
    }
}

@MainActor
struct PDFViewerViewModelTests {
    private func makeSUT(
        pdfDocumentSource: PDFViewerDocumentSource = .local(URL(fileURLWithPath: "/tmp/test.pdf")),
        documentURLUseCase: some PDFDocumentURLUseCaseProtocol,
        documentLoader: some PDFDocumentLoading = MockPDFDocumentLoader(
            document: MockPDFDocumentLoader.makeDocument()
        )
    ) -> PDFViewerViewModel {
        PDFViewerViewModel(
            dependency: PDFViewerViewModel.Dependency(
                pdfDocumentSource: pdfDocumentSource,
                documentURLUseCase: documentURLUseCase,
                documentLoader: documentLoader,
                fileName: "test.pdf"
            )
        )
    }

    /// Suspends until `sut.state` equals `expected`, re-registering
    /// observation tracking after each change until the condition holds.
    private func awaitState(_ sut: PDFViewerViewModel, equals expected: PDFViewerViewModel.ViewState) async {
        while sut.state != expected {
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = sut.state
                } onChange: {
                    continuation.resume()
                }
            }
        }
    }

    private func awaitDocumentParsed(_ sut: PDFViewerViewModel) async {
        while sut.pdfDocument == nil {
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = sut.pdfDocument
                } onChange: {
                    continuation.resume()
                }
            }
        }
    }

    @Test func loadDocumentURL_progressEvent_setsLoadingProgress() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.progress(0.4))

        await awaitState(sut, equals: .loading(progress: 0.4))
        task.cancel()
    }

    @Test func loadDocumentURL_readyEvent_parsesDocumentAndSetsReadyState() async {
        let url = URL(fileURLWithPath: "/tmp/downloaded.pdf")
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))

        await awaitDocumentParsed(sut)

        let isReady = switch sut.state {
        case .ready: true
        default: false
        }
        #expect(isReady)
        #expect(sut.pdfDocument != nil)
        task.cancel()
    }

    @Test func loadDocumentURL_loaderReturnsNil_setsFailedState() async {
        let url = URL(fileURLWithPath: "/tmp/damaged.pdf")
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(document: nil)
        )

        sut.isChromeHidden = true

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))
        continuation.finish()
        await task.value

        #expect(sut.pdfDocument == nil)
        #expect(sut.state == .failed(.init(.documentUnreadable, isShowingDamagedFileAlert: true)))
        #expect(!sut.isChromeHidden)
    }

    @Test func loadDocumentURL_streamThrows_setsFailedState() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))
        sut.isChromeHidden = true

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.finish(throwing: PDFDocumentLoadError.transferFailed)

        await awaitState(sut, equals: .failed(.init(.downloadFailed)))
        #expect(!sut.isChromeHidden)
        task.cancel()
    }

    @Test func retryAfterDownloadFailure_resolvesNodeAgain() async {
        let url = URL(fileURLWithPath: "/tmp/downloaded.pdf")
        var attempt = 0
        let useCase = MockPDFDocumentURLUseCase {
            attempt += 1
            return AsyncThrowingStream { continuation in
                if attempt == 1 {
                    continuation.finish(throwing: PDFDocumentLoadError.transferFailed)
                } else {
                    continuation.yield(.ready(url))
                    continuation.finish()
                }
            }
        }
        let sut = makeSUT(
            pdfDocumentSource: .node(NodeEntity(handle: 1)),
            documentURLUseCase: useCase
        )

        await sut.loadDocumentFromSource()
        #expect(sut.state == .failed(.init(.downloadFailed)))

        await sut.retryDocumentLoad()

        #expect(sut.state.isReady)
        #expect(useCase.localDocumentURLCallCount == 2)
    }

    @Test func retryAfterUnreadableLocalFile_resolvesSourceAgain() async {
        let url = URL(fileURLWithPath: "/tmp/damaged.pdf")
        let useCase = MockPDFDocumentURLUseCase {
            AsyncThrowingStream { continuation in
                continuation.yield(.ready(url))
                continuation.finish()
            }
        }
        let sut = makeSUT(
            documentURLUseCase: useCase,
            documentLoader: MockPDFDocumentLoader(document: nil)
        )

        await sut.loadDocumentFromSource()
        #expect(sut.state == .failed(.init(.documentUnreadable, isShowingDamagedFileAlert: true)))

        await sut.retryDocumentLoad()

        #expect(sut.state == .failed(.init(.documentUnreadable, isShowingDamagedFileAlert: true)))
        #expect(useCase.localDocumentURLCallCount == 2)
    }

    @Test func retry_cancelledAttemptLateEvents_doNotChangeState() async {
        let (failedStream, failedContinuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let (cancelledStream, cancelledContinuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let (currentStream, currentContinuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        var streams = [failedStream, cancelledStream, currentStream]
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase { streams.removeFirst() })

        failedContinuation.finish(throwing: PDFDocumentLoadError.transferFailed)
        await sut.loadDocumentFromSource()

        let cancelledTask = Task { await sut.retryDocumentLoad() }
        cancelledContinuation.yield(.progress(0.2))
        await awaitState(sut, equals: .loading(progress: 0.2))
        cancelledTask.cancel()
        await cancelledTask.value

        let currentTask = Task { await sut.loadDocumentFromSource() }
        cancelledContinuation.yield(.progress(0.9))
        cancelledContinuation.finish(throwing: PDFDocumentLoadError.transferFailed)
        currentContinuation.yield(.progress(0.5))
        await awaitState(sut, equals: .loading(progress: 0.5))

        currentContinuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        currentContinuation.finish()
        await currentTask.value

        #expect(sut.state.isReady)
    }

    @Test func loadDocumentURL_afterDocumentLoaded_doesNotResolveAgain() async {
        let url = URL(fileURLWithPath: "/tmp/downloaded.pdf")
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let useCase = MockPDFDocumentURLUseCase(stream: stream)
        let sut = makeSUT(documentURLUseCase: useCase)

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))
        await awaitDocumentParsed(sut)
        task.cancel()

        await sut.loadDocumentFromSource()

        #expect(useCase.localDocumentURLCallCount == 1)
    }

    @Test func chromeVisibility_startsShownAndToggles() {
        let (stream, _) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        #expect(!sut.isChromeHidden)
        sut.isChromeHidden.toggle()
        #expect(sut.isChromeHidden)
        sut.isChromeHidden.toggle()
        #expect(!sut.isChromeHidden)
    }

    @Test func thumbnailVisibility_startsHiddenAndChangesIndependently() {
        let (stream, _) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        #expect(!sut.isShowingThumbnails)
        sut.isShowingThumbnails = true
        #expect(sut.isShowingThumbnails)
        #expect(!sut.isChromeHidden)
    }

    @Test func loadDocumentURL_readyEvent_setsPageState() async {
        let url = URL(fileURLWithPath: "/tmp/downloaded.pdf")
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(
                document: MockPDFDocumentLoader.makeDocument(pageCount: 3)
            )
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))

        await awaitDocumentParsed(sut)

        let pageCount: Int? = switch sut.state {
        case .ready(_, let pagingState): pagingState.pageCount
        default: nil
        }
        #expect(pageCount == 3)
        #expect(sut.currentPageIndex == 0)
        #expect(sut.thumbnailLoader != nil)
        #expect(
            sut.pageIndicatorText == Strings.Localizable.PdfPreview.pageOfTotal(1, 3)
        )
        task.cancel()
    }

    @Test func loadDocumentURL_thumbnailDocumentFailsToParse_hasNoThumbnailLoader() async {
        let url = URL(fileURLWithPath: "/tmp/downloaded.pdf")
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: FirstLoadOnlyPDFDocumentLoader()
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))
        await awaitDocumentParsed(sut)

        #expect(sut.state.isReady)
        #expect(sut.thumbnailLoader == nil)
        task.cancel()
    }

    @Test func updateCurrentPageIndex_acceptsOnlyDocumentPages() async {
        let url = URL(fileURLWithPath: "/tmp/downloaded.pdf")
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(
                document: MockPDFDocumentLoader.makeDocument(pageCount: 3)
            )
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))
        await awaitDocumentParsed(sut)

        sut.currentPageIndex = 2
        #expect(sut.currentPageIndex == 2)
        #expect(
            sut.pageIndicatorText == Strings.Localizable.PdfPreview.pageOfTotal(3, 3)
        )

        sut.currentPageIndex = -1
        sut.currentPageIndex = 3
        #expect(sut.currentPageIndex == 2)
        task.cancel()
    }

    @Test func didSelectThumbnail_navigatesToPageAndHidesThumbnails() async {
        let (sut, task) = await loadedSUT(pageCount: 3)
        sut.isShowingThumbnails = true

        sut.didSelectThumbnail(at: 2)

        #expect(sut.currentPageIndex == 2)
        #expect(sut.isProgrammaticallyScrollingToCurrentPage)
        #expect(!sut.isShowingThumbnails)
        task.cancel()
    }

    @Test func didSelectThumbnail_outsideDocument_doesNotNavigate() async {
        let (sut, task) = await loadedSUT(pageCount: 3)

        sut.didSelectThumbnail(at: 3)

        #expect(sut.currentPageIndex == 0)
        #expect(!sut.isProgrammaticallyScrollingToCurrentPage)
        task.cancel()
    }

    private func loadedSUT(pageCount: Int) async -> (PDFViewerViewModel, Task<Void, Never>) {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(
                document: MockPDFDocumentLoader.makeDocument(pageCount: pageCount)
            )
        )
        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        return (sut, task)
    }

}
