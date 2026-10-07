import Combine
import CoreGraphics

@MainActor
final class AutoFittingPDFViewModel {
    struct ZoomState: Equatable {
        let zoomScale: CGFloat
        let minZoomScale: CGFloat
        let zoomScaleForSizeToFit: CGFloat
    }

    struct ZoomStateUpdate: Equatable {
        let minZoomScale: CGFloat
        let zoomScale: CGFloat?
        let shouldScrollToTop: Bool
    }

    @Published private(set) var zoomStateUpdate: ZoomStateUpdate?
    @Published private(set) var didTriggerInitialScrollToTop = false

    var zoomState: ZoomState? {
        didSet {
            recalculateZoomStateUpdate()
        }
    }

    private var lastZoomScaleForSizeToFit: CGFloat = 0
    private var needsInitialFitAndTopScroll = false

    func documentDidChange() {
        needsInitialFitAndTopScroll = true
        didTriggerInitialScrollToTop = false
    }

    private func recalculateZoomStateUpdate() {
        guard let zoomState else { return }
        guard zoomState.zoomScaleForSizeToFit > 0 else { return }
        let didUpdateZoomScaleForSizeToFit = abs(
            lastZoomScaleForSizeToFit - zoomState.zoomScaleForSizeToFit
        ) >= 0.0001
        guard needsInitialFitAndTopScroll || didUpdateZoomScaleForSizeToFit else { return }

        let shouldUpdateZoomScale = needsInitialFitAndTopScroll
            || abs(zoomState.zoomScale - zoomState.minZoomScale) < 0.0001

        zoomStateUpdate = ZoomStateUpdate(
            minZoomScale: zoomState.zoomScaleForSizeToFit,
            zoomScale: shouldUpdateZoomScale
                ? zoomState.zoomScaleForSizeToFit
                : nil,
            shouldScrollToTop: needsInitialFitAndTopScroll
        )
        // Must come after `zoomStateUpdate` is assigned: its sink applies the
        // scroll to top synchronously, so this only fires once that landed.
        if needsInitialFitAndTopScroll {
            didTriggerInitialScrollToTop = true
        }
        lastZoomScaleForSizeToFit = zoomState.zoomScaleForSizeToFit
        needsInitialFitAndTopScroll = false
    }
}
