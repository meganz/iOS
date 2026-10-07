import Combine
@testable import MEGAPDFViewer
import Testing

@MainActor
struct AutoFittingPDFViewModelTests {
    @Test
    func documentChangePublishesInitialFitAndTopScroll() {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75
        )

        #expect(sut.zoomStateUpdate == .init(
            minZoomScale: 0.75,
            zoomScale: 0.75,
            shouldScrollToTop: true
        ))
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func sameSizedDocumentChangePublishesInitialFitAndTopScroll() {
        let sut = AutoFittingPDFViewModel()
        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75
        )
        sut.documentDidChange()

        sut.zoomState = .init(
            zoomScale: 2,
            minZoomScale: 0.75,
            zoomScaleForSizeToFit: 0.75
        )

        #expect(sut.zoomStateUpdate == .init(
            minZoomScale: 0.75,
            zoomScale: 0.75,
            shouldScrollToTop: true
        ))
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func zeroFitScaleDoesNotConsumePendingDocumentChange() {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()

        sut.zoomState = .init(
            zoomScale: 0,
            minZoomScale: 0,
            zoomScaleForSizeToFit: 0
        )
        #expect(sut.zoomStateUpdate == nil)
        #expect(!sut.didTriggerInitialScrollToTop)

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75
        )
        #expect(sut.zoomStateUpdate == .init(
            minZoomScale: 0.75,
            zoomScale: 0.75,
            shouldScrollToTop: true
        ))
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func updatedFitPreservesUserZoom() {
        let sut = AutoFittingPDFViewModel()

        sut.zoomState = .init(
            zoomScale: 2,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75
        )

        #expect(sut.zoomStateUpdate == .init(
            minZoomScale: 0.75,
            zoomScale: nil,
            shouldScrollToTop: false
        ))
        #expect(!sut.didTriggerInitialScrollToTop)
    }

    @Test
    func updatedFitTracksMinimumScaleWhenNotZoomed() {
        let sut = AutoFittingPDFViewModel()

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75
        )

        #expect(sut.zoomStateUpdate == .init(
            minZoomScale: 0.75,
            zoomScale: 0.75,
            shouldScrollToTop: false
        ))
        #expect(!sut.didTriggerInitialScrollToTop)
    }

    @Test
    func initialScrollToTopSignalFollowsZoomStateUpdate() {
        let sut = AutoFittingPDFViewModel()
        var events: [String] = []
        let zoomSubscription = sut.$zoomStateUpdate
            .compactMap { $0 }
            .sink { _ in events.append("zoomStateUpdate") }
        let triggerSubscription = sut.$didTriggerInitialScrollToTop
            .filter { $0 }
            .sink { _ in events.append("didTriggerInitialScrollToTop") }

        sut.documentDidChange()
        sut.zoomState = .init(zoomScale: 1, minZoomScale: 1, zoomScaleForSizeToFit: 0.5)

        #expect(events == ["zoomStateUpdate", "didTriggerInitialScrollToTop"])
        zoomSubscription.cancel()
        triggerSubscription.cancel()
    }

    @Test
    func documentChangeRearmsInitialScrollToTop() {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()
        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75
        )
        #expect(sut.didTriggerInitialScrollToTop)

        sut.documentDidChange()

        #expect(!sut.didTriggerInitialScrollToTop)
    }
}
