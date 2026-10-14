import Foundation
import MEGADomainMock
@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@MainActor
private final class PDFAnalyticsRecorder: PDFViewerTrackingUseCaseProtocol {
    private(set) var events: [PDFViewerAnalyticsEvent] = []

    nonisolated func track(_ event: PDFViewerAnalyticsEvent) {
        MainActor.assumeIsolated { events.append(event) }
    }
}

private struct AnalyticsDocumentURLUseCase: PDFDocumentURLUseCaseProtocol {
    enum ResolutionError: Error { case failed }
    var fails = false

    func localDocumentURL(for source: PDFViewerDocumentSource) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        AsyncThrowingStream {
            if fails {
                $0.finish(throwing: ResolutionError.failed)
            } else {
                $0.yield(.progress(0.5))
                $0.yield(.ready(URL(fileURLWithPath: "/tmp/analytics-test.pdf")))
                $0.finish()
            }
        }
    }
}

@MainActor
struct PDFViewerAnalyticsTests {
    private func makeSUT(
        recorder: PDFAnalyticsRecorder,
        downloadFails: Bool = false,
        documentURLUseCase: (any PDFDocumentURLUseCaseProtocol)? = nil,
        readable: Bool = true,
        hasOutline: Bool = false,
        outlineReader: any PDFOutlineReading = MockPDFOutlineReader(),
    ) -> PDFViewerViewModel {
        let lastPage = MockPDFViewerLastPageUseCase()
        let document = MockPDFDocumentLoader.makeDocument(pageCount: 2)
        if hasOutline {
            let root = PDFOutline()
            let child = PDFOutline()
            child.label = "Fixture heading"
            root.insertChild(child, at: 0)
            document.outlineRoot = root
        }
        let documentLoader = MockPDFDocumentLoader(document: readable ? document : nil)
        let outlineLoadingUseCase = PDFOutlineLoadingUseCase(
            documentLoader: documentLoader,
            outlineReader: outlineReader
        )
        return PDFViewerViewModel(dependency: .init(
            pdfDocumentSource: .local(URL(fileURLWithPath: "/tmp/analytics-test.pdf")),
            documentURLUseCase: documentURLUseCase ?? AnalyticsDocumentURLUseCase(fails: downloadFails),
            documentLoadingUseCase: PDFViewerDocumentLoadingUseCase(
                documentLoader: documentLoader,
                outlineLoadingUseCase: outlineLoadingUseCase,
                lastPageUseCase: lastPage
            ),
            lastPageUseCase: lastPage,
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(),
            node: nil,
            nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
            fileName: "analytics-test.pdf",
            trackingUseCase: recorder
        ))
    }

    @Test func construction_emitsNothing() {
        let recorder = PDFAnalyticsRecorder()
        _ = makeSUT(recorder: recorder)
        #expect(recorder.events.isEmpty)
    }

    private func makeController(recorder: PDFAnalyticsRecorder) -> PDFViewerViewController {
        let lastPage = MockPDFViewerLastPageUseCase()
        let documentLoader = MockPDFDocumentLoader(document: MockPDFDocumentLoader.makeDocument())
        let outlineLoadingUseCase = PDFOutlineLoadingUseCase(
            documentLoader: documentLoader,
            outlineReader: MockPDFOutlineReader()
        )
        return PDFViewerViewController(dependency: .init(
            pdfDocumentSource: .local(URL(fileURLWithPath: "/tmp/analytics-test.pdf")),
            documentURLUseCase: AnalyticsDocumentURLUseCase(),
            documentLoadingUseCase: PDFViewerDocumentLoadingUseCase(
                documentLoader: documentLoader,
                outlineLoadingUseCase: outlineLoadingUseCase,
                lastPageUseCase: lastPage
            ),
            lastPageUseCase: lastPage,
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(),
            node: nil,
            nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
            fileName: "analytics-test.pdf",
            transferIndicatorToolbarFactory: .indicator(),
            onClose: {},
            onLinkTapped: { _ in },
            trackingUseCase: recorder
        ))
    }

    private func makeLifecycleTracking(
        recorder: PDFAnalyticsRecorder,
        onViewerPresented: @escaping @MainActor () -> Void = {}
    ) -> PDFViewerLifecycleTracking {
        PDFViewerLifecycleTracking(trackingUseCase: recorder, onViewerPresented: onViewerPresented)
    }

    @Test func controllerAppearanceWithTemporaryDisappearance_emitsOnlyOneScreen() {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeController(recorder: recorder)
        sut.viewDidAppear(false)
        sut.viewDidDisappear(false)
        sut.viewDidAppear(false)
        #expect(recorder.events == [.screenPresented])
    }

    @Test func controllerConstructionAndUnconfirmedDisappearance_emitNothing() {
        let recorder = PDFAnalyticsRecorder()
        makeController(recorder: recorder).viewDidDisappear(false)
        #expect(recorder.events.isEmpty)
    }

    @Test func consumerPresentationHook_runsOnceAfterActualAppearance() {
        let recorder = PDFAnalyticsRecorder()
        var opens = 0
        let sut = makeLifecycleTracking(recorder: recorder, onViewerPresented: { opens += 1 })
        #expect(opens == 0)
        sut.viewerDidAppear()
        sut.viewerDidAppear()
        #expect(opens == 1)
        #expect(recorder.events == [.screenPresented])
    }

    @Test func passwordUnlock_tracksDisplaySuccessOnceWithoutWrongAttemptEvents() async {
        let recorder = PDFAnalyticsRecorder()
        let document = MockLockablePDFDocument()
        document.insert(PDFPage(), at: 0)
        let url = URL(fileURLWithPath: "/tmp/locked-analytics.pdf")
        let unlocker = MockPDFDocumentUnlocker(result: false)
        let loader = MockPDFViewerDocumentLoadingUseCase(
            document: document, url: url, documentUnlocker: unlocker
        )
        let sut = PDFViewerViewModel(dependency: .init(
            pdfDocumentSource: .local(url),
            documentURLUseCase: AnalyticsDocumentURLUseCase(),
            documentLoadingUseCase: loader,
            lastPageUseCase: MockPDFViewerLastPageUseCase(),
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(),
            node: nil,
            nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
            fileName: "fixture.pdf",
            trackingUseCase: recorder
        ))
        await sut.loadDocumentFromSource()
        #expect(recorder.events.isEmpty)
        sut.password = "incorrect-fixture-password"
        await sut.submitPassword()
        #expect(recorder.events.isEmpty)
        unlocker.result = true
        sut.password = "correct-fixture-password"
        await sut.submitPassword()
        await sut.submitPassword()
        #expect(recorder.events == [.passwordUnlocked, .loadSucceeded])
    }

    @Test func repeatedAppearance_emitsScreenOnce() {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeLifecycleTracking(recorder: recorder)
        sut.viewerDidAppear()
        sut.viewerDidAppear()
        #expect(recorder.events == [.screenPresented])
    }

    @Test func confirmedExit_emitsCloseOnce() {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeLifecycleTracking(recorder: recorder)
        sut.viewerDidAppear()
        sut.viewerDidClose()
        sut.viewerDidClose()
        #expect(recorder.events == [.screenPresented, .closed])
    }

    @Test func unpresentedViewer_emitsNoClose() {
        let recorder = PDFAnalyticsRecorder()
        makeLifecycleTracking(recorder: recorder).viewerDidClose()
        #expect(recorder.events.isEmpty)
    }

    @Test func controlsBeforeReady_emitNothing() {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        sut.isShowingThumbnails = true
        sut.didSelectThumbnail(at: 0)
        sut.didOpenOutline()
        sut.requestSearch()
        #expect(recorder.events.isEmpty)
    }

    @Test func viewerAppearance_doesNotDuplicateConsumerFileOpen() {
        let recorder = PDFAnalyticsRecorder()
        makeLifecycleTracking(recorder: recorder).viewerDidAppear()
        #expect(!recorder.events.contains(.offlineFileOpened))
    }

    @Test func successfulLoadAndTaskRestart_emitOneOutcome() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        await sut.loadDocumentFromSource()
        await sut.loadDocumentFromSource()
        #expect(recorder.events == [.loadSucceeded])
    }

    @Test func supersededAttemptFailure_leavesCurrentOutcomeAndState() async {
        let recorder = PDFAnalyticsRecorder()
        let urlUseCase = FirstAttemptGatedDocumentURLUseCase()
        let sut = makeSUT(recorder: recorder, documentURLUseCase: urlUseCase)
        let firstAttempt = Task { await sut.loadDocumentFromSource() }
        while urlUseCase.firstAttemptContinuation == nil { await Task.yield() }

        await sut.loadDocumentFromSource()
        urlUseCase.firstAttemptContinuation?.finish(throwing: AnalyticsDocumentURLUseCase.ResolutionError.failed)
        await firstAttempt.value

        #expect(recorder.events == [.loadSucceeded])
        #expect(sut.state.isReady)
    }

    @Test(arguments: [true, false])
    func failedLoad_emitsBoundedReason(downloadFails: Bool) async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder, downloadFails: downloadFails, readable: false)
        await sut.loadDocumentFromSource()
        #expect(recorder.events == [.loadFailed(downloadFails ? .downloadFailed : .documentUnreadable)])
    }

    @Test func retry_emitsOnlyTerminalOutcomes() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder, readable: false)
        await sut.loadDocumentFromSource()
        await sut.retryDocumentLoad()
        #expect(recorder.events == [.loadFailed(.documentUnreadable), .loadFailed(.documentUnreadable)])
    }

    @Test func thumbnails_openTransitionsAndSamePageSelectionCount() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        await sut.loadDocumentFromSource()
        sut.isShowingThumbnails = true
        sut.isShowingThumbnails = true
        sut.didSelectThumbnail(at: 0)
        sut.isShowingThumbnails = true
        #expect(recorder.events == [.loadSucceeded, .thumbnailsOpened, .thumbnailSelected, .thumbnailsOpened])
    }

    @Test func invalidThumbnailSelection_emitsNothing() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        await sut.loadDocumentFromSource()
        sut.didSelectThumbnail(at: 99)
        #expect(!recorder.events.contains(.thumbnailSelected))
    }

    @Test func contents_openAndSamePageSelectionCountButAutomaticHighlightDoesNot() async {
        let recorder = PDFAnalyticsRecorder()
        let item = PDFOutlineItem(id: "0", title: "Fixture heading", level: 0, pageIndex: 0)
        let sut = makeSUT(
            recorder: recorder, hasOutline: true,
            outlineReader: MockPDFOutlineReader(items: .init(inOutlineOrder: [item], inPageOrder: [item]))
        )
        await sut.loadDocumentFromSource()
        await sut.loadOutlineIfNeeded()
        sut.currentPageIndex = 0
        sut.didOpenOutline()
        sut.didOpenOutline()
        sut.didSelectOutlineItem(item)
        sut.didOpenOutline()
        #expect(recorder.events == [.loadSucceeded, .contentsOpened, .contentsItemSelected, .contentsOpened])
    }

    @Test func contentsWhileExtracting_countsOpeningBeforeItemsArrive() async {
        let recorder = PDFAnalyticsRecorder()
        let reader = AnalyticsDelayedOutlineReader()
        let sut = makeSUT(recorder: recorder, hasOutline: true, outlineReader: reader)
        await sut.loadDocumentFromSource()
        let load = Task { await sut.loadOutlineIfNeeded() }
        await reader.waitUntilStarted()
        sut.didOpenOutline()
        let eventsBeforeFinishing = recorder.events
        await reader.finish()
        await load.value
        #expect(eventsBeforeFinishing == [.loadSucceeded, .contentsOpened])
        #expect(recorder.events == eventsBeforeFinishing)
    }

    @Test func toolbarIntent_isSeparateFromNativeSessionStart() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        await sut.loadDocumentFromSource()
        sut.requestSearch()
        #expect(recorder.events == [.loadSucceeded, .searchToolbarSelected])
    }

    @Test func nativeSessions_deduplicateBeginAndIgnoreLateOldEnd() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        await sut.loadDocumentFromSource()
        let first = UUID(), second = UUID()
        sut.searchSessionDidBegin(first)
        sut.searchSessionDidBegin(first)
        sut.searchSessionDidEnd(first)
        sut.searchSessionDidBegin(second)
        sut.searchSessionDidEnd(first)
        sut.searchSessionDidBegin(second)
        #expect(recorder.events == [.loadSucceeded, .searchSessionStarted, .searchSessionStarted])
    }

    @Test func resultTransitions_ignoreFirstRepeatedAndNewGenerationHighlights() async {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        await sut.loadDocumentFromSource()
        let session = UUID(), generation = UUID()
        sut.searchSessionDidBegin(session)
        sut.searchResultDidChange(sessionID: session, generationID: generation, resultID: 0)
        sut.searchResultDidChange(sessionID: session, generationID: generation, resultID: 0)
        sut.searchResultDidChange(sessionID: session, generationID: generation, resultID: 1)
        sut.searchResultDidChange(sessionID: session, generationID: UUID(), resultID: 0)
        #expect(recorder.events == [.loadSucceeded, .searchSessionStarted, .searchResultItemSelected])
    }

    @Test func inactiveSessionHighlights_emitNothing() {
        let recorder = PDFAnalyticsRecorder()
        let sut = makeSUT(recorder: recorder)
        sut.searchResultDidChange(sessionID: UUID(), generationID: UUID(), resultID: 1)
        #expect(recorder.events.isEmpty)
    }
}

private final class FirstAttemptGatedDocumentURLUseCase: PDFDocumentURLUseCaseProtocol, @unchecked Sendable {
    private(set) var firstAttemptContinuation: AsyncThrowingStream<PDFDocumentLoadEvent, any Error>.Continuation?
    private var attemptCount = 0

    func localDocumentURL(for source: PDFViewerDocumentSource) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        attemptCount += 1
        if attemptCount == 1 {
            return AsyncThrowingStream { firstAttemptContinuation = $0 }
        }
        return AsyncThrowingStream {
            $0.yield(.ready(URL(fileURLWithPath: "/tmp/analytics-test.pdf")))
            $0.finish()
        }
    }
}

private actor AnalyticsDelayedOutlineReader: PDFOutlineReading {
    private var started = false
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var finishContinuation: CheckedContinuation<Void, Never>?

    nonisolated func shouldLoadOutline(document: PDFDocument) -> Bool {
        (document.outlineRoot?.numberOfChildren ?? 0) > 0
    }

    func outlineItems(
        forDocumentAt url: URL,
        documentLoader: some PDFDocumentLoading,
        unlockPassword: String?
    ) async -> PDFOutlineItems {
        started = true
        startContinuation?.resume()
        startContinuation = nil
        await withCheckedContinuation { finishContinuation = $0 }
        return .init(inOutlineOrder: [], inPageOrder: [])
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startContinuation = $0 }
    }

    func finish() {
        finishContinuation?.resume()
        finishContinuation = nil
    }
}
