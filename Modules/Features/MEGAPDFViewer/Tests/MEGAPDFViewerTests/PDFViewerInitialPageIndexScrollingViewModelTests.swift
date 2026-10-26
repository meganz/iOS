import Combine
import CoreGraphics
@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewerInitialPageIndexScrollingViewModelTests {
    private let settledInsets = PDFViewerInitialPageIndexScrollingViewModel.ContentInsetState(
        scrollViewAdjustedContentInsetTop: 97.67,
        pdfViewSafeAreaInsetTop: 97.67
    )
    private let unsettledInsets = PDFViewerInitialPageIndexScrollingViewModel.ContentInsetState(
        scrollViewAdjustedContentInsetTop: 0,
        pdfViewSafeAreaInsetTop: 97.67
    )
    /// A scroll view inset that never matches the safe area.
    private let mismatchedInsets = PDFViewerInitialPageIndexScrollingViewModel.ContentInsetState(
        scrollViewAdjustedContentInsetTop: 20,
        pdfViewSafeAreaInsetTop: 97.67
    )

    @Test
    func requestsInitialPageWhenInsetsSettleBeforeScrollToTop() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = settledInsets
        didTriggerInitialScrollToTop.send(true)

        #expect(sut.initialPageNavigationRequest == 15)
    }

    @Test
    func requestsInitialPageWhenInsetsSettleAfterScrollToTop() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = unsettledInsets
        didTriggerInitialScrollToTop.send(true)
        #expect(sut.initialPageNavigationRequest == nil)

        sut.contentInsetState = settledInsets

        #expect(sut.initialPageNavigationRequest == 15)
    }

    @Test
    func doesNotRequestWhileInsetsAreUnsettled() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = unsettledInsets
        didTriggerInitialScrollToTop.send(true)

        #expect(sut.initialPageNavigationRequest == nil)
    }

    @Test
    func doesNotRequestBeforeScrollToTop() {
        let (sut, _) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = settledInsets

        #expect(sut.initialPageNavigationRequest == nil)
    }

    @Test(arguments: [97.4, 97.9] as [CGFloat])
    func toleratesSubPointInsetRounding(scrollViewInsetTop: CGFloat) {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = .init(
            scrollViewAdjustedContentInsetTop: scrollViewInsetTop,
            pdfViewSafeAreaInsetTop: 97.67
        )
        didTriggerInitialScrollToTop.send(true)

        #expect(sut.initialPageNavigationRequest == 15)
    }

    @Test
    func requestsWhenMismatchedInsetIsUnchangedAfterScrollToTop() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = mismatchedInsets
        didTriggerInitialScrollToTop.send(true)
        #expect(sut.initialPageNavigationRequest == nil)

        sut.contentInsetState = mismatchedInsets

        #expect(sut.initialPageNavigationRequest == 15)
    }

    @Test
    func ignoresUnchangedInsetBeforeScrollToTop() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = unsettledInsets
        sut.contentInsetState = unsettledInsets
        didTriggerInitialScrollToTop.send(true)

        #expect(sut.initialPageNavigationRequest == nil)
    }

    @Test
    func doesNotRequestWithoutInitialPageIndex() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: nil)

        sut.contentInsetState = settledInsets
        didTriggerInitialScrollToTop.send(true)

        #expect(sut.initialPageNavigationRequest == nil)
    }

    @Test
    func settledInsetsStaySettledWhenTheyChangeAgain() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)

        sut.contentInsetState = settledInsets
        sut.contentInsetState = unsettledInsets
        didTriggerInitialScrollToTop.send(true)

        #expect(sut.initialPageNavigationRequest == 15)
    }

    @Test
    func requestsAtMostOnce() {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(initialPageIndex: 15)
        var requests: [Int] = []
        let subscription = sut.$initialPageNavigationRequest
            .compactMap { $0 }
            .sink { requests.append($0) }

        sut.contentInsetState = settledInsets
        didTriggerInitialScrollToTop.send(true)
        didTriggerInitialScrollToTop.send(true)
        sut.contentInsetState = settledInsets

        #expect(requests == [15])
        subscription.cancel()
    }

    @Test(.timeLimit(.minutes(1)))
    func requestsInitialPageWhenInsetsAreNeverReportedAfterScrollToTop() async {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(
            initialPageIndex: 15,
            contentScrollViewInsetsSettleTimeout: .milliseconds(50)
        )

        didTriggerInitialScrollToTop.send(true)
        #expect(sut.initialPageNavigationRequest == nil)
        for await didSettle in sut.$didSettleInitialScrollPosition.values where didSettle {
            break
        }

        #expect(sut.initialPageNavigationRequest == 15)
        #expect(sut.didSettleInitialScrollPosition)
    }

    @Test
    func doesNotSettleOnTimeoutBeforeScrollToTop() async throws {
        let (sut, _) = makeSUT(
            initialPageIndex: 15,
            contentScrollViewInsetsSettleTimeout: .milliseconds(50)
        )

        sut.contentInsetState = unsettledInsets
        try await Task.sleep(for: .milliseconds(300))

        #expect(sut.initialPageNavigationRequest == nil)
        #expect(!sut.didSettleInitialScrollPosition)
    }

    @Test
    func requestsAtMostOnceWhenInsetsSettleBeforeTimeout() async throws {
        let (sut, didTriggerInitialScrollToTop) = makeSUT(
            initialPageIndex: 15,
            contentScrollViewInsetsSettleTimeout: .milliseconds(50)
        )
        var requests: [Int] = []
        let subscription = sut.$initialPageNavigationRequest
            .compactMap { $0 }
            .sink { requests.append($0) }

        didTriggerInitialScrollToTop.send(true)
        sut.contentInsetState = settledInsets
        try await Task.sleep(for: .milliseconds(300))

        #expect(requests == [15])
        subscription.cancel()
    }

    private func makeSUT(
        initialPageIndex: Int?,
        contentScrollViewInsetsSettleTimeout: Duration = .seconds(3600)
    ) -> (
        sut: PDFViewerInitialPageIndexScrollingViewModel,
        didTriggerInitialScrollToTop: CurrentValueSubject<Bool, Never>
    ) {
        let sut = PDFViewerInitialPageIndexScrollingViewModel(
            contentScrollViewInsetsSettleTimeout: contentScrollViewInsetsSettleTimeout
        )
        sut.initialPageIndex = initialPageIndex
        let didTriggerInitialScrollToTop = CurrentValueSubject<Bool, Never>(false)
        sut.startObservingScrollToTop(didTriggerInitialScrollToTop: didTriggerInitialScrollToTop)
        return (sut, didTriggerInitialScrollToTop)
    }
}
