import Foundation
import MEGAL10n
@testable import MEGAPDFViewer
import Observation
import PDFKit
import Testing

private final class MockPDFDocumentURLUseCase: PDFDocumentURLUseCaseProtocol {
    private let stream: AsyncThrowingStream<PDFDocumentLoadEvent, any Error>
    private(set) var localDocumentURLCallCount = 0

    init(stream: AsyncThrowingStream<PDFDocumentLoadEvent, any Error>) {
        self.stream = stream
    }

    func localDocumentURL(for pdfDocumentSource: PDFViewerDocumentSource) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        localDocumentURLCallCount += 1
        return stream
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

@MainActor
struct PDFViewerViewModelTests {
    private func makeSUT(
        documentURLUseCase: some PDFDocumentURLUseCaseProtocol,
        documentLoader: some PDFDocumentLoading = MockPDFDocumentLoader(
            document: MockPDFDocumentLoader.makeDocument()
        )
    ) -> PDFViewerViewModel {
        PDFViewerViewModel(
            dependency: PDFViewerViewModel.Dependency(
                pdfDocumentSource: .local(URL(fileURLWithPath: "/tmp/test.pdf")),
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

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(url))
        continuation.finish()
        await task.value

        #expect(sut.pdfDocument == nil)
        #expect(sut.state == .failed)
    }

    @Test func loadDocumentURL_streamThrows_setsFailedState() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.finish(throwing: PDFDocumentLoadError.transferFailed)

        await awaitState(sut, equals: .failed)
        task.cancel()
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
        #expect(
            sut.pageIndicatorText == Strings.Localizable.PdfPreview.pageOfTotal(1, 3)
        )
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

}
