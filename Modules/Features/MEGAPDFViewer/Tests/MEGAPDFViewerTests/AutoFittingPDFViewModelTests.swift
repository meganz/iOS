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
    }
}
