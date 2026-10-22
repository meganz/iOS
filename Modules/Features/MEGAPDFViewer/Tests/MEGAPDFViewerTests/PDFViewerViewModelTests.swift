import Foundation
import MEGADomain
import MEGADomainMock
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

/// Parses the first request only, like a file that disappears between the
/// viewer's parse and the thumbnails' parse.
private final class FirstLoadOnlyPDFDocumentLoader: PDFDocumentLoading, @unchecked Sendable {
    private var hasLoaded = false

    func loadDocument(url: URL) -> PDFDocument? {
        guard !hasLoaded else { return nil }
        hasLoaded = true
        return MockPDFDocumentLoader.makeDocument()
    }
}

private actor DelayedPDFViewerDocumentLoadingUseCase: PDFViewerDocumentLoadingUseCaseProtocol {
    private var hasStartedLoading = false
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var loadContinuation: CheckedContinuation<Void, Never>?

    nonisolated func loadDocument(at url: URL) async throws(CancellationError) -> PDFViewerDocumentLoadingState {
        await waitForFinish()
        return .failed
    }

    nonisolated(nonsending) func unlockAndLoad(
        document: PDFDocument,
        documentUrl: URL,
        password: String
    ) async throws -> PDFViewerDocumentLoadingState {
        .failed
    }

    private func waitForFinish() async {
        await withCheckedContinuation {
            loadContinuation = $0
            hasStartedLoading = true
            startContinuation?.resume()
            startContinuation = nil
        }
    }

    func waitUntilLoadingStarts() async {
        guard !hasStartedLoading else { return }
        await withCheckedContinuation { startContinuation = $0 }
    }

    func finishLoading() {
        loadContinuation?.resume()
        loadContinuation = nil
    }
}

private actor DelayedPDFOutlineReader: PDFOutlineReading {
    let items: PDFOutlineItems
    private var hasStartedReading = false
    private var firstReadWasCancelled = false
    private var readCount = 0
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var readContinuation: CheckedContinuation<Void, Never>?

    init(items: PDFOutlineItems) {
        self.items = items
    }

    nonisolated func shouldLoadOutline(document: PDFDocument) -> Bool {
        (document.outlineRoot?.numberOfChildren ?? 0) > 0
    }

    func outlineItems(
        forDocumentAt url: URL,
        documentLoader: some PDFDocumentLoading,
        unlockPassword: String?
    ) async -> PDFOutlineItems {
        readCount += 1
        guard readCount == 1 else { return items }
        hasStartedReading = true
        startContinuation?.resume()
        startContinuation = nil
        await withCheckedContinuation { readContinuation = $0 }
        firstReadWasCancelled = Task.isCancelled
        return items
    }

    func waitUntilReadingStarts() async {
        guard !hasStartedReading else { return }
        await withCheckedContinuation { startContinuation = $0 }
    }

    func finishReading() {
        readContinuation?.resume()
        readContinuation = nil
    }

    func numberOfReads() -> Int { readCount }

    func wasFirstReadCancelled() -> Bool { firstReadWasCancelled }
}

@MainActor
struct PDFViewerViewModelTests {
    private func makeSUT(
        pdfDocumentSource: PDFViewerDocumentSource = .local(URL(fileURLWithPath: "/tmp/test.pdf")),
        documentURLUseCase: some PDFDocumentURLUseCaseProtocol,
        documentLoader: some PDFDocumentLoading = MockPDFDocumentLoader(
            document: MockPDFDocumentLoader.makeDocument()
        ),
        documentLoadingUseCase: (any PDFViewerDocumentLoadingUseCaseProtocol)? = nil,
        lastPageUseCase: some PDFViewerLastPageUseCaseProtocol = MockPDFViewerLastPageUseCase(),
        leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol = MockLeftOffItemRecordUseCase(),
        node: NodeEntity? = nil,
        outlineReader: any PDFOutlineReading = MockPDFOutlineReader(),
        nearestOutlineItemUseCase: any PDFNearestOutlineItemUseCaseProtocol = PDFNearestOutlineItemUseCase(),
        actionContext: PDFViewerActionContext = .init(),
        hasMoreAction: Bool = false,
        hasDownloadAction: Bool = false
    ) -> PDFViewerViewModel {
        let outlineLoadingUseCase = PDFOutlineLoadingUseCase(
            documentLoader: documentLoader,
            outlineReader: outlineReader
        )
        return PDFViewerViewModel(
            dependency: PDFViewerViewModel.Dependency(
                pdfDocumentSource: pdfDocumentSource,
                documentURLUseCase: documentURLUseCase,
                documentLoadingUseCase: documentLoadingUseCase ?? PDFViewerDocumentLoadingUseCase(
                    documentLoader: documentLoader,
                    outlineLoadingUseCase: outlineLoadingUseCase,
                    lastPageUseCase: lastPageUseCase
                ),
                lastPageUseCase: lastPageUseCase,
                leftOffItemRecordUseCase: leftOffItemRecordUseCase,
                node: node,
                nearestOutlineItemUseCase: nearestOutlineItemUseCase,
                fileName: "test.pdf",
                actionContext: actionContext,
                hasMoreAction: hasMoreAction,
                hasDownloadAction: hasDownloadAction
            )
        )
    }

    @Test(arguments: [false, true])
    func nodeContext_usesMoreEvenForCachedLocalFile(isLink: Bool) {
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init { $0.finish() }),
            actionContext: .init(hasNode: true, isLink: isLink),
            hasMoreAction: true, hasDownloadAction: true
        )

        #expect(sut.trailingAction == .more)
    }

    @Test
    func offlineLocalFile_usesDownloadEvenWhenMoreCallbackExists() {
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init { $0.finish() }),
            hasMoreAction: true, hasDownloadAction: true
        )

        #expect(sut.trailingAction == .download)
    }

    @Test(arguments: [false, true])
    func missingLinkOrChatNode_doesNotBecomeOffline(isChat: Bool) {
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init { $0.finish() }),
            actionContext: .init(isLink: !isChat, isChat: isChat),
            hasMoreAction: true, hasDownloadAction: true
        )

        #expect(sut.trailingAction == .none)
    }

    @Test
    func unresolvedNodeSource_doesNotOfferOfflineDownload() {
        let sut = makeSUT(
            pdfDocumentSource: .node(NodeEntity(handle: 1)),
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init { $0.finish() }),
            hasMoreAction: true, hasDownloadAction: true
        )

        #expect(sut.trailingAction == .none)
    }

    @Test(arguments: [false, true])
    func unavailableCallback_hidesCorrespondingAction(hasNode: Bool) {
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init { $0.finish() }),
            actionContext: .init(hasNode: hasNode)
        )

        #expect(sut.trailingAction == .none)
    }

    @Test
    func failedLoad_keepsNodeMoreAction() async {
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init {
                $0.finish(throwing: PDFDocumentLoadError.transferFailed)
            }),
            actionContext: .init(hasNode: true), hasMoreAction: true
        )

        await sut.loadDocumentFromSource()

        #expect(sut.state.isFailed)
        #expect(sut.trailingAction == .more)
    }

    @Test
    func failedOfflineParse_keepsDownloadAction() async {
        let url = URL(fileURLWithPath: "/tmp/offline.pdf")
        let sut = makeSUT(
            pdfDocumentSource: .local(url),
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: .init {
                $0.yield(.ready(url))
                $0.finish()
            }),
            documentLoader: MockPDFDocumentLoader(document: nil),
            hasDownloadAction: true
        )

        await sut.loadDocumentFromSource()

        #expect(sut.state.isFailed)
        #expect(sut.trailingAction == .download)
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

    private func preparingSUT(
        lastPageUseCase: MockPDFViewerLastPageUseCase = MockPDFViewerLastPageUseCase()
    ) async -> (PDFViewerViewModel, Task<Void, Never>) {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(
                document: MockPDFDocumentLoader.makeDocument(pageCount: 20)
            ),
            lastPageUseCase: lastPageUseCase
        )
        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        return (sut, task)
    }

    @Test func loadedDocument_preparesDisplayBeforeReady() async {
        let (sut, task) = await preparingSUT(
            lastPageUseCase: MockPDFViewerLastPageUseCase(loadLastPageIndexResult: 11)
        )
        defer { task.cancel() }

        #expect(sut.state.isPreparingDisplay)
        #expect(!sut.state.isReady)
        #expect(sut.pdfDocument?.pageCount == 20)
        #expect(sut.initialPageIndex == 11)
    }

    @Test func finishingDisplayPreparation_makesViewerReadyWithSameDocument() async {
        let (sut, task) = await preparingSUT()
        defer { task.cancel() }
        #expect(sut.state.isPreparingDisplay)
        let document = sut.pdfDocument

        sut.displayerDidFinishPreparingForDisplayAndInteraction()

        #expect(sut.state.isReady)
        #expect(sut.pdfDocument === document)
    }

    @Test func restartedLoadDuringPreparation_keepsPreparingTheSameDocument() async {
        let (sut, task) = await preparingSUT()
        defer { task.cancel() }
        let document = sut.pdfDocument

        await sut.loadDocumentFromSource()

        #expect(sut.state.isPreparingDisplay)
        #expect(sut.pdfDocument === document)
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

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
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

    @Test func loadDocumentURL_cancelledWhileLoading_ignoresLateResult() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let delayedLoadingUseCase = DelayedPDFViewerDocumentLoadingUseCase()
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoadingUseCase: delayedLoadingUseCase
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        continuation.finish()
        await delayedLoadingUseCase.waitUntilLoadingStarts()
        task.cancel()
        await delayedLoadingUseCase.finishLoading()
        await task.value

        #expect(sut.state == .loading(progress: nil))
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

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
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

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
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

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        let readyState: PDFViewerViewModel.ViewState.ReadyState? = switch sut.state {
        case .ready(let readyState): readyState
        default: nil
        }
        #expect(readyState?.pagingState.pageCount == 3)
        #expect(readyState?.outlineState.outlineItems.inOutlineOrder.isEmpty == true)
        #expect(readyState?.outlineState.outlineItems.inPageOrder.isEmpty == true)
        #expect(readyState?.outlineState.outlineLoadingState?.shouldLoadOutline == false)
        #expect(readyState?.outlineState.outlineLoadingState?.isLoadingOutline == false)
        #expect(readyState?.outlineState.isShowingOutline == false)
        #expect(readyState?.outlineState.activeOutlineItemID == nil)
        #expect(readyState?.searchState.request == nil)
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

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(sut.state.isReady)
        #expect(sut.thumbnailLoader == nil)
        task.cancel()
    }

    @Test func requestSearch_whenReady_preservesPagingAndOutlineState() async {
        let sut = await loadedSUT(
            items: PDFOutlineItems(
                inOutlineOrder: [item("0", page: 0)],
                inPageOrder: [item("0", page: 0)]
            )
        )
        sut.currentPageIndex = 2
        sut.isShowingOutline = true
        sut.isShowingThumbnails = true
        sut.isChromeHidden = true

        sut.requestSearch()

        #expect(sut.searchRequest == .present)
        #expect(sut.currentPageIndex == 2)
        #expect(sut.isShowingOutline)
        #expect(!sut.isShowingThumbnails)
        #expect(!sut.isChromeHidden)
    }

    @Test func showingThumbnails_requestsSearchDismissal() async {
        let sut = await loadedSUT(
            items: PDFOutlineItems(inOutlineOrder: [], inPageOrder: [])
        )

        sut.isShowingThumbnails = true

        #expect(sut.searchRequest == .dismiss)
    }

    @Test func openingOutline_requestsSearchDismissal() async {
        let sut = await loadedSUT(
            items: PDFOutlineItems(
                inOutlineOrder: [item("0", page: 0)],
                inPageOrder: [item("0", page: 0)]
            )
        )

        sut.didOpenOutline()

        #expect(sut.searchRequest == .dismiss)
    }

    @Test func searchIntent_doesNotEscapeLoadingState() {
        let (stream, _) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))
        sut.isShowingThumbnails = true
        sut.isChromeHidden = true

        sut.requestSearch()
        sut.searchRequest = .present

        #expect(sut.searchRequest == nil)
        #expect(sut.isShowingThumbnails)
        #expect(sut.isChromeHidden)
    }

    @Test func searchIntent_doesNotEscapeFailedState() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))
        let task = Task { await sut.loadDocumentFromSource() }
        continuation.finish(throwing: PDFDocumentLoadError.transferFailed)
        await awaitState(sut, equals: .failed(.init(.downloadFailed)))

        sut.requestSearch()
        sut.searchRequest = .present

        #expect(sut.searchRequest == nil)
        #expect(sut.state == .failed(.init(.downloadFailed)))
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
        sut.displayerDidFinishPreparingForDisplayAndInteraction()

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

    private func loadedSUT(
        pageCount: Int,
        lastPageUseCase: MockPDFViewerLastPageUseCase = MockPDFViewerLastPageUseCase(),
        leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase = MockLeftOffItemRecordUseCase(),
        node: NodeEntity? = nil,
        finishesDisplayPreparation: Bool = true
    ) async -> (PDFViewerViewModel, Task<Void, Never>) {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(
                document: MockPDFDocumentLoader.makeDocument(pageCount: pageCount)
            ),
            lastPageUseCase: lastPageUseCase,
            leftOffItemRecordUseCase: leftOffItemRecordUseCase,
            node: node
        )
        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        if finishesDisplayPreparation {
            sut.displayerDidFinishPreparingForDisplayAndInteraction()
        }
        return (sut, task)
    }

    @Test func saveLastReadPage_whenReady_savesCurrentPageIndex() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let (sut, task) = await loadedSUT(pageCount: 10, lastPageUseCase: lastPageUseCase)
        task.cancel()

        sut.currentPageIndex = 3
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase) == [
            .saveLastPageIndex(index: 3, documentIdentifier: "any-fingerprint")
        ])
    }

    @Test func saveLastReadPage_whenReaderReturnsToFirstPage_savesZero() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let (sut, task) = await loadedSUT(pageCount: 10, lastPageUseCase: lastPageUseCase)
        task.cancel()

        sut.currentPageIndex = 3
        sut.currentPageIndex = 0
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase) == [
            .saveLastPageIndex(index: 0, documentIdentifier: "any-fingerprint")
        ])
    }

    @Test func loadDocument_passesResumePageToView() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(loadLastPageIndexResult: 4)
        let (sut, task) = await loadedSUT(pageCount: 10, lastPageUseCase: lastPageUseCase)

        #expect(sut.initialPageIndex == 4)
        task.cancel()
    }

    @Test func saveLastReadPage_duringDisplayPreparation_savesNothing() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(loadLastPageIndexResult: 11)
        let (sut, task) = await loadedSUT(pageCount: 20, lastPageUseCase: lastPageUseCase, finishesDisplayPreparation: false)
        task.cancel()

        sut.isScrolledToTopDidChange(true)
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase).isEmpty)
    }

    @Test func saveLastReadPage_afterDisplayPreparation_savesCurrentPage() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(loadLastPageIndexResult: 11)
        let (sut, task) = await loadedSUT(pageCount: 20, lastPageUseCase: lastPageUseCase)
        task.cancel()

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        sut.currentPageIndex = 11
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase) == [
            .saveLastPageIndex(index: 11, documentIdentifier: "any-fingerprint")
        ])
    }

    @Test(arguments: [(3, true), (7, true), (8, false), (9, false)])
    func recordLeftOffItem_recordsUntilNearCompletion(pageIndex: Int, shouldRecord: Bool) async {
        let leftOffItemRecordUseCase = MockLeftOffItemRecordUseCase()
        let (sut, task) = await loadedSUT(
            pageCount: 10,
            leftOffItemRecordUseCase: leftOffItemRecordUseCase,
            node: NodeEntity(name: "report.pdf", handle: 7)
        )
        task.cancel()

        sut.currentPageIndex = pageIndex
        await sut.recordLeftOffItem()

        #expect(leftOffItemRecordUseCase.record_Calls.map(\.handle) == (shouldRecord ? [7] : []))
        #expect(leftOffItemRecordUseCase.remove_Calls == (shouldRecord ? [] : [7]))
    }

    @Test func recordLeftOffItem_duringDisplayPreparation_recordsNothing() async {
        let leftOffItemRecordUseCase = MockLeftOffItemRecordUseCase()
        let (sut, task) = await loadedSUT(
            pageCount: 10,
            lastPageUseCase: MockPDFViewerLastPageUseCase(loadLastPageIndexResult: 9),
            leftOffItemRecordUseCase: leftOffItemRecordUseCase,
            node: NodeEntity(name: "report.pdf", handle: 7),
            finishesDisplayPreparation: false
        )
        task.cancel()

        sut.isScrolledToTopDidChange(true)
        await sut.recordLeftOffItem()

        #expect(leftOffItemRecordUseCase.record_Calls.isEmpty)
        #expect(leftOffItemRecordUseCase.remove_Calls.isEmpty)
    }

    @Test func recordLeftOffItem_withoutNode_recordsNothing() async {
        let leftOffItemRecordUseCase = MockLeftOffItemRecordUseCase()
        let (sut, task) = await loadedSUT(pageCount: 10, leftOffItemRecordUseCase: leftOffItemRecordUseCase)
        task.cancel()

        await sut.recordLeftOffItem()

        #expect(leftOffItemRecordUseCase.record_Calls.isEmpty)
        #expect(leftOffItemRecordUseCase.remove_Calls.isEmpty)
    }

    @Test func saveLastReadPage_whenScrolledToTop_savesFirstPage() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let (sut, task) = await loadedSUT(pageCount: 10, lastPageUseCase: lastPageUseCase)
        task.cancel()

        sut.currentPageIndex = 2
        sut.isScrolledToTopDidChange(true)
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase) == [
            .saveLastPageIndex(index: 0, documentIdentifier: "any-fingerprint")
        ])
    }

    @Test func saveLastReadPage_afterLeavingTop_savesCurrentPage() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let (sut, task) = await loadedSUT(pageCount: 10, lastPageUseCase: lastPageUseCase)
        task.cancel()

        sut.currentPageIndex = 2
        sut.isScrolledToTopDidChange(true)
        sut.isScrolledToTopDidChange(false)
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase) == [
            .saveLastPageIndex(index: 2, documentIdentifier: "any-fingerprint")
        ])
    }

    @Test func saveLastReadPage_whenDocumentNotIdentified_savesNothing() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(
            documentIdentifierForLastViewedPageIndexResult: nil
        )
        let (sut, task) = await loadedSUT(pageCount: 10, lastPageUseCase: lastPageUseCase)
        task.cancel()

        sut.currentPageIndex = 3
        await sut.saveLastReadPage()

        #expect(saveInvocations(lastPageUseCase).isEmpty)
    }

    @Test func saveLastReadPage_whenNotReady_savesNothing() async {
        let (stream, _) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            lastPageUseCase: lastPageUseCase
        )

        await sut.saveLastReadPage()

        #expect(lastPageUseCase.invocations.isEmpty)
    }

    private func saveInvocations(
        _ lastPageUseCase: MockPDFViewerLastPageUseCase
    ) -> [MockPDFViewerLastPageUseCase.Invocation] {
        lastPageUseCase.invocations.filter {
            if case .saveLastPageIndex = $0 { true } else { false }
        }
    }

    @Test func outline_beforeLoad_isHiddenWithNoItems() {
        let (stream, _) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        #expect(sut.outlineItems.isEmpty)
        #expect(!sut.isShowingOutline)
        #expect(!sut.showsOutlineButton)
    }

    @Test func loadDocumentURL_readyEvent_carriesOutlineItems() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let outline = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0), item("1", page: 4)],
            inPageOrder: [item("0", page: 0), item("1", page: 4)]
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(document: documentWithOutline()),
            outlineReader: MockPDFOutlineReader(items: outline)
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        await sut.loadOutlineIfNeeded()

        #expect(sut.outlineItems == outline.inOutlineOrder)
        #expect(sut.pageSortedOutlineItems == outline.inPageOrder)
        #expect(sut.showsOutlineButton)
        task.cancel()
    }

    @Test func loadDocumentURL_outlineReadingContinuesAfterReady() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let outline = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0)],
            inPageOrder: [item("0", page: 0)]
        )
        let reader = DelayedPDFOutlineReader(items: outline)
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(document: documentWithOutline()),
            outlineReader: reader
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        let outlineTask = Task { await sut.loadOutlineIfNeeded() }
        await reader.waitUntilReadingStarts()

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(sut.state.isReady)
        #expect(sut.isLoadingOutline)
        #expect(sut.showsOutlineButton)
        #expect(sut.outlineItems.isEmpty)
        sut.didOpenOutline()
        #expect(sut.isShowingOutline)
        #expect(sut.activeOutlineItemID == nil)

        await reader.finishReading()
        await outlineTask.value

        #expect(sut.outlineItems == outline.inOutlineOrder)
        #expect(sut.activeOutlineItemID == "0")
        #expect(!sut.isLoadingOutline)
        task.cancel()
    }

    @Test func loadDocumentURL_cancelledOutlineReading_discardsResult() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let outline = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0)],
            inPageOrder: [item("0", page: 0)]
        )
        let reader = DelayedPDFOutlineReader(items: outline)
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(document: documentWithOutline()),
            outlineReader: reader
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        let outlineTask = Task { await sut.loadOutlineIfNeeded() }
        await reader.waitUntilReadingStarts()
        outlineTask.cancel()
        await reader.finishReading()
        await outlineTask.value

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(sut.state.isReady)
        #expect(!sut.isLoadingOutline)
        #expect(sut.outlineItems.isEmpty)
        task.cancel()
    }

    @Test func loadDocumentURL_restartedTask_resumesPendingOutlineRead() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let outline = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0)],
            inPageOrder: [item("0", page: 0)]
        )
        let reader = DelayedPDFOutlineReader(items: outline)
        let useCase = MockPDFDocumentURLUseCase(stream: stream)
        let sut = makeSUT(
            documentURLUseCase: useCase,
            documentLoader: MockPDFDocumentLoader(document: documentWithOutline()),
            outlineReader: reader
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        let outlineTask = Task { await sut.loadOutlineIfNeeded() }
        await reader.waitUntilReadingStarts()
        outlineTask.cancel()
        await reader.finishReading()
        await outlineTask.value

        #expect(await reader.wasFirstReadCancelled())
        #expect(!sut.isLoadingOutline)
        await sut.loadDocumentFromSource()
        await sut.loadOutlineIfNeeded()

        let readCount = await reader.numberOfReads()
        #expect(readCount == 2)
        #expect(useCase.localDocumentURLCallCount == 1)
        #expect(sut.outlineItems == outline.inOutlineOrder)
        #expect(!sut.isLoadingOutline)
        task.cancel()
    }

    @Test func loadDocumentURL_restartedOutlineTaskWhilePreviousReadIsPending_loadsItems() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let outline = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0)],
            inPageOrder: [item("0", page: 0)]
        )
        let reader = DelayedPDFOutlineReader(items: outline)
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(document: documentWithOutline()),
            outlineReader: reader
        )

        let documentTask = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        let firstOutlineTask = Task { await sut.loadOutlineIfNeeded() }
        await reader.waitUntilReadingStarts()
        firstOutlineTask.cancel()

        let secondOutlineTask = Task { await sut.loadOutlineIfNeeded() }
        await secondOutlineTask.value

        #expect(await reader.numberOfReads() == 2)
        #expect(sut.outlineItems == outline.inOutlineOrder)
        #expect(!sut.isLoadingOutline)

        await reader.finishReading()
        await firstOutlineTask.value
        #expect(sut.outlineItems == outline.inOutlineOrder)
        #expect(!sut.isLoadingOutline)
        documentTask.cancel()
    }

    @Test func loadDocumentURL_noOutlineItems_hidesOutlineButton() async {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream))

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()

        #expect(!sut.showsOutlineButton)
        task.cancel()
    }

    @Test func didOpenOutline_beforeFirstItem_hasNoHighlight() async {
        let sut = await loadedSUT(
            items: PDFOutlineItems(
                inOutlineOrder: [item("0", page: 3)],
                inPageOrder: [item("0", page: 3)]
            )
        )
        sut.currentPageIndex = 1

        sut.didOpenOutline()

        #expect(sut.activeOutlineItemID == nil)
        #expect(sut.isShowingOutline)
    }

    @Test func didOpenOutline_setsHighlightFromCurrentPage() async {
        let items = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0), item("1", page: 4), item("2", page: 8)],
            inPageOrder: [item("0", page: 0), item("1", page: 4), item("2", page: 8)]
        )
        let sut = await loadedSUT(items: items)
        sut.currentPageIndex = 5

        sut.didOpenOutline()

        #expect(sut.activeOutlineItemID == "1")
        #expect(sut.isShowingOutline)
    }

    @Test func currentPageChange_doesNotRecalculateHighlight() async {
        let items = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0), item("1", page: 4), item("2", page: 8)],
            inPageOrder: [item("0", page: 0), item("1", page: 4), item("2", page: 8)]
        )
        let sut = await loadedSUT(items: items)
        sut.currentPageIndex = 5
        sut.didOpenOutline()

        sut.currentPageIndex = 8

        #expect(sut.activeOutlineItemID == "1")
    }

    @Test func reopenOutline_refreshesHighlight() async {
        let items = PDFOutlineItems(
            inOutlineOrder: [item("0", page: 0), item("1", page: 4), item("2", page: 8)],
            inPageOrder: [item("0", page: 0), item("1", page: 4), item("2", page: 8)]
        )
        let sut = await loadedSUT(items: items)
        sut.currentPageIndex = 5
        sut.didOpenOutline()
        sut.isShowingOutline = false
        sut.currentPageIndex = 8

        sut.didOpenOutline()

        #expect(sut.activeOutlineItemID == "2")
    }

    @Test func didSelectOutlineItem_navigatesAndClosesSheetAndThumbnails() async {
        let sut = await loadedSUT(items: PDFOutlineItems(
            inOutlineOrder: [item("2", page: 2)],
            inPageOrder: [item("2", page: 2)]
        ))
        sut.isShowingOutline = true
        sut.isShowingThumbnails = true

        sut.didSelectOutlineItem(item("2", page: 2))

        #expect(sut.currentPageIndex == 2)
        #expect(sut.isProgrammaticallyScrollingToCurrentPage)
        #expect(!sut.isShowingOutline)
        #expect(!sut.isShowingThumbnails)
    }

    private func documentWithOutline() -> PDFDocument {
        let document = MockPDFDocumentLoader.makeDocument(pageCount: 10)
        let root = PDFOutline()
        root.insertChild(PDFOutline(), at: 0)
        document.outlineRoot = root
        return document
    }

    private func item(_ id: String, page: Int, level: Int = 0) -> PDFOutlineItem {
        PDFOutlineItem(id: id, title: id, level: level, pageIndex: page)
    }

    private func loadedSUT(
        items: PDFOutlineItems,
        nearestOutlineItemUseCase: any PDFNearestOutlineItemUseCaseProtocol =
            PDFNearestOutlineItemUseCase()
    ) async -> PDFViewerViewModel {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let sut = makeSUT(
            documentURLUseCase: MockPDFDocumentURLUseCase(stream: stream),
            documentLoader: MockPDFDocumentLoader(
                document: documentWithOutline()
            ),
            outlineReader: MockPDFOutlineReader(items: items),
            nearestOutlineItemUseCase: nearestOutlineItemUseCase
        )

        let task = Task { await sut.loadDocumentFromSource() }
        continuation.yield(.ready(URL(fileURLWithPath: "/tmp/downloaded.pdf")))
        await awaitDocumentParsed(sut)
        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        await sut.loadOutlineIfNeeded()
        task.cancel()
        return sut
    }
}
