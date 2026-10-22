import Combine
import CoreGraphics

@MainActor
final class AutoFittingPDFViewModel {
    struct ZoomState: Equatable {
        let zoomScale: CGFloat
        let minZoomScale: CGFloat
        let zoomScaleForSizeToFit: CGFloat
        let widestPageWidth: CGFloat
        let pageBreakMargin: CGFloat
    }

    struct ZoomStateUpdate: Equatable {
        struct ZoomThenScroll: Equatable {
            let minZoomScale: CGFloat
            let maxZoomScale: CGFloat
            let zoomScale: CGFloat?
            let shouldScrollToTop: Bool
        }

        let pageBreakMargin: CGFloat
        let zoomThenScroll: ZoomThenScroll?
    }

    @Published private(set) var zoomStateUpdate: ZoomStateUpdate?
    @Published private(set) var didTriggerInitialScrollToTop = false

    var zoomState: ZoomState? {
        didSet {
            recalculateZoomStateUpdate()
        }
    }

    // An A4 page on an iPhone in portrait fits at about 0.65, so PDFKit's
    // default `maxScaleFactor` of 5 lets it zoom about 7.7x past the fit.
    private static let maxZoomScaleRelativeToFit: CGFloat = 8
    private static let defaultMaxZoomScale: CGFloat = 5
    private static let defaultPageBreakMarginInPageSpace: CGFloat = 4
    private static let targetPageBreakGapOnScreenAtFit: CGFloat = 4

    private var lastZoomScaleForSizeToFit: CGFloat = 0
    private var needsInitialFitAndTopScroll = false

    func documentDidChange() {
        needsInitialFitAndTopScroll = true
        didTriggerInitialScrollToTop = false
    }

    private func recalculateZoomStateUpdate() {
        guard let zoomState else { return }
        guard zoomState.zoomScaleForSizeToFit > 0 else { return }
        let fitWidthOnScreen = Self.fitWidthOnScreen(of: zoomState)
        let pageBreakMarginInPageSpace = Self.pageBreakMarginInPageSpace(
            forFitWidthOnScreen: fitWidthOnScreen,
            widestPageWidthInPageSpace: zoomState.widestPageWidth
        )
        let zoomScaleForSizeToFit = Self.zoomScaleForSizeToFit(
            of: zoomState,
            withPageBreakMarginInPageSpace: pageBreakMarginInPageSpace,
            fitWidthOnScreen: fitWidthOnScreen
        )
        let didUpdateZoomScaleForSizeToFit = abs(
            lastZoomScaleForSizeToFit - zoomScaleForSizeToFit
        ) >= 0.0001
        guard needsInitialFitAndTopScroll || didUpdateZoomScaleForSizeToFit else { return }

        zoomStateUpdate = ZoomStateUpdate(
            pageBreakMargin: pageBreakMarginInPageSpace,
            zoomThenScroll: Self.zoomThenScroll(
                for: zoomState,
                zoomScaleForSizeToFit: zoomScaleForSizeToFit,
                isInitialFit: needsInitialFitAndTopScroll
            )
        )
        // Must come after `zoomStateUpdate` is assigned: its sink applies the
        // scroll to top synchronously, so this only fires once that landed.
        if needsInitialFitAndTopScroll {
            didTriggerInitialScrollToTop = true
        }
        lastZoomScaleForSizeToFit = zoomScaleForSizeToFit
        needsInitialFitAndTopScroll = false
    }

    private static func fitWidthOnScreen(of zoomState: ZoomState) -> CGFloat {
        // `PDFView` fits the widest page plus both margins, in page space,
        // rounded up to a whole page unit, into its width on screen:
        // `zoomScaleForSizeToFit = width / ceil(widestPageWidth + 2 * margin)`.
        // The width therefore follows from the current fit and margin.
        zoomState.zoomScaleForSizeToFit
            * roundedUpToWholeUnit(zoomState.widestPageWidth + 2 * zoomState.pageBreakMargin)
    }

    private static func pageBreakMarginInPageSpace(
        forFitWidthOnScreen fitWidthOnScreen: CGFloat,
        widestPageWidthInPageSpace: CGFloat
    ) -> CGFloat {
        // `PDFView` fits `pageAndMarginsInPageSpace =
        // widestPageWidthInPageSpace + 2 * marginInPageSpace`, rounded up to a
        // whole page unit, into `fitWidthOnScreen`.
        // - Zoom scale to fit is
        //   `zoomScaleToFit = fitWidthOnScreen / pageAndMarginsInPageSpace`.
        // - Each margin shows at that scale as
        //   `marginInPageSpace * zoomScaleToFit`.
        //
        // - Smallest total reaching the target: `widestPageWidthInPageSpace *
        //   fitWidthOnScreen / (fitWidthOnScreen - gapsOnScreen)` is the
        //   `pageAndMarginsInPageSpace` at which the page alone fills
        //   `fitWidthOnScreen - gapsOnScreen`, leaving exactly
        //   `targetPageBreakGapOnScreenAtFit` each side.
        // - Rounding split across sides: `PDFView` lays the rounding out
        //   right of the page, so both margins widen to that whole total,
        //   which centres the page: `marginInPageSpace =
        //   (pageAndMarginsInPageSpace - widestPageWidthInPageSpace) / 2`.
        let gapsOnScreen = 2 * targetPageBreakGapOnScreenAtFit
        guard widestPageWidthInPageSpace > 0, fitWidthOnScreen > gapsOnScreen else {
            return defaultPageBreakMarginInPageSpace
        }
        let pageAndMarginsInPageSpace = roundedUpToWholeUnit(
            widestPageWidthInPageSpace * fitWidthOnScreen / (fitWidthOnScreen - gapsOnScreen)
        )
        let marginInPageSpace = (pageAndMarginsInPageSpace - widestPageWidthInPageSpace) / 2
        return min(marginInPageSpace, defaultPageBreakMarginInPageSpace)
    }

    private static func zoomScaleForSizeToFit(
        of zoomState: ZoomState,
        withPageBreakMarginInPageSpace pageBreakMarginInPageSpace: CGFloat,
        fitWidthOnScreen: CGFloat
    ) -> CGFloat {
        // A changed margin is published with the fit it produces, so a single
        // update applies both.
        guard abs(pageBreakMarginInPageSpace - zoomState.pageBreakMargin) >= 0.0001 else {
            return zoomState.zoomScaleForSizeToFit
        }
        return fitWidthOnScreen
            / roundedUpToWholeUnit(zoomState.widestPageWidth + 2 * pageBreakMarginInPageSpace)
    }

    private static func zoomThenScroll(
        for zoomState: ZoomState,
        zoomScaleForSizeToFit: CGFloat,
        isInitialFit: Bool
    ) -> ZoomStateUpdate.ZoomThenScroll {
        let isAtMinimumZoomScale = abs(zoomState.zoomScale - zoomState.minZoomScale) < 0.0001
        return ZoomStateUpdate.ZoomThenScroll(
            minZoomScale: zoomScaleForSizeToFit,
            maxZoomScale: max(defaultMaxZoomScale, zoomScaleForSizeToFit * maxZoomScaleRelativeToFit),
            zoomScale: isInitialFit || isAtMinimumZoomScale ? zoomScaleForSizeToFit : nil,
            shouldScrollToTop: isInitialFit
        )
    }

    private static func roundedUpToWholeUnit(_ value: CGFloat) -> CGFloat {
        // Tolerates the floating-point error of a total already whole.
        (value - 0.000001).rounded(.up)
    }
}
