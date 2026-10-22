import Combine
import CoreGraphics
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
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )

        #expect(sut.zoomStateUpdate == .init(
            pageBreakMargin: 4,
            zoomThenScroll: .init(
                minZoomScale: 0.75,
                maxZoomScale: 6,
                zoomScale: 0.75,
                shouldScrollToTop: true
            )
        ))
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func sameSizedDocumentChangePublishesInitialFitAndTopScroll() {
        let sut = AutoFittingPDFViewModel()
        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )
        sut.documentDidChange()

        sut.zoomState = .init(
            zoomScale: 2,
            minZoomScale: 0.75,
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )

        #expect(sut.zoomStateUpdate == .init(
            pageBreakMargin: 4,
            zoomThenScroll: .init(
                minZoomScale: 0.75,
                maxZoomScale: 6,
                zoomScale: 0.75,
                shouldScrollToTop: true
            )
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
            zoomScaleForSizeToFit: 0,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )
        #expect(sut.zoomStateUpdate == nil)
        #expect(!sut.didTriggerInitialScrollToTop)

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )
        #expect(sut.zoomStateUpdate == .init(
            pageBreakMargin: 4,
            zoomThenScroll: .init(
                minZoomScale: 0.75,
                maxZoomScale: 6,
                zoomScale: 0.75,
                shouldScrollToTop: true
            )
        ))
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func updatedFitPreservesUserZoom() {
        let sut = AutoFittingPDFViewModel()

        sut.zoomState = .init(
            zoomScale: 2,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )

        #expect(sut.zoomStateUpdate == .init(
            pageBreakMargin: 4,
            zoomThenScroll: .init(
                minZoomScale: 0.75,
                maxZoomScale: 6,
                zoomScale: nil,
                shouldScrollToTop: false
            )
        ))
        #expect(!sut.didTriggerInitialScrollToTop)
    }

    @Test
    func updatedFitTracksMinimumScaleWhenNotZoomed() {
        let sut = AutoFittingPDFViewModel()

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )

        #expect(sut.zoomStateUpdate == .init(
            pageBreakMargin: 4,
            zoomThenScroll: .init(
                minZoomScale: 0.75,
                maxZoomScale: 6,
                zoomScale: 0.75,
                shouldScrollToTop: false
            )
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
        sut.zoomState = .init(zoomScale: 1, minZoomScale: 1, zoomScaleForSizeToFit: 0.5, widestPageWidth: 612, pageBreakMargin: 4)

        #expect(events == ["zoomStateUpdate", "didTriggerInitialScrollToTop"])
        zoomSubscription.cancel()
        triggerSubscription.cancel()
    }

    @Test(arguments: [
        (0.5, 612, 4, 5),
        (0.625, 612, 4, 5),
        (0.6339, 612, 4, 5.0712),
        (7.5577, 50, 1, 60.4616),
        (98.25, 3.84, 0.08, 786)
    ] as [(CGFloat, CGFloat, CGFloat, CGFloat)])
    func maxZoomScaleIsEightTimesFitAndAtLeastFive(
        zoomScaleForSizeToFit: CGFloat,
        widestPageWidth: CGFloat,
        pageBreakMargin: CGFloat,
        expectedMaxZoomScale: CGFloat
    ) throws {
        let sut = AutoFittingPDFViewModel()

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: zoomScaleForSizeToFit,
            widestPageWidth: widestPageWidth,
            pageBreakMargin: pageBreakMargin
        )

        let maxZoomScale = try #require(sut.zoomStateUpdate?.zoomThenScroll?.maxZoomScale)
        #expect(abs(maxZoomScale - expectedMaxZoomScale) < 0.0001)
    }

    @Test(arguments: [
        (32.75, 3.84, 0.08, 393.0 / 4),
        (6.7759, 50, 1, 393.0 / 52),
        (3.6389, 100, 1.5, 393.0 / 103),
        (1.8894, 200, 2.5, 393.0 / 205),
        (1.2760, 300, 3.5, 393.0 / 307)
    ] as [(CGFloat, CGFloat, CGFloat, CGFloat)])
    func pageAboveUnitFitPublishesCentringMarginWithTheFitItProduces(
        zoomScaleForSizeToFit: CGFloat,
        widestPageWidth: CGFloat,
        expectedMargin: CGFloat,
        expectedZoomScaleForSizeToFit: CGFloat
    ) throws {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: zoomScaleForSizeToFit,
            widestPageWidth: widestPageWidth,
            pageBreakMargin: 4
        )

        let update = try #require(sut.zoomStateUpdate)
        #expect(abs(update.pageBreakMargin - expectedMargin) < 0.0001)
        let zoomThenScroll = try #require(update.zoomThenScroll)
        #expect(abs(zoomThenScroll.minZoomScale - expectedZoomScaleForSizeToFit) < 0.0001)
        #expect(zoomThenScroll.shouldScrollToTop)
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func settledMarginPublishesFitAndInitialScrollToTop() throws {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()
        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 32.75,
            widestPageWidth: 3.84,
            pageBreakMargin: 4
        )

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 98.25,
            widestPageWidth: 3.84,
            pageBreakMargin: 0.08
        )

        let update = try #require(sut.zoomStateUpdate)
        #expect(abs(update.pageBreakMargin - 0.08) < 0.0001)
        let zoomThenScroll = try #require(update.zoomThenScroll)
        #expect(zoomThenScroll.minZoomScale == 98.25)
        #expect(zoomThenScroll.maxZoomScale == 786)
        #expect(zoomThenScroll.zoomScale == 98.25)
        #expect(zoomThenScroll.shouldScrollToTop)
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test(arguments: [
        (1, 100),
        (0.6339, 612),
        (0.66, 595.28)
    ] as [(CGFloat, CGFloat)])
    func pageAtOrBelowUnitFitKeepsPDFKitDefaultMarginAndPublishesFit(
        zoomScaleForSizeToFit: CGFloat,
        widestPageWidth: CGFloat
    ) throws {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()

        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: zoomScaleForSizeToFit,
            widestPageWidth: widestPageWidth,
            pageBreakMargin: 4
        )

        let update = try #require(sut.zoomStateUpdate)
        #expect(update.pageBreakMargin == 4)
        #expect(update.zoomThenScroll?.minZoomScale == zoomScaleForSizeToFit)
        #expect(sut.didTriggerInitialScrollToTop)
    }

    @Test
    func documentChangeRearmsInitialScrollToTop() {
        let sut = AutoFittingPDFViewModel()
        sut.documentDidChange()
        sut.zoomState = .init(
            zoomScale: 1,
            minZoomScale: 1,
            zoomScaleForSizeToFit: 0.75,
            widestPageWidth: 612,
            pageBreakMargin: 4
        )
        #expect(sut.didTriggerInitialScrollToTop)

        sut.documentDidChange()

        #expect(!sut.didTriggerInitialScrollToTop)
    }
}
