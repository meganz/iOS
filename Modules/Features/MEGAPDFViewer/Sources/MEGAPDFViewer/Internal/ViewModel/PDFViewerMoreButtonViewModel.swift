import Observation

@MainActor
@Observable
final class PDFViewerMoreButtonViewModel {
    /// Hides the transfer indicator while the iPad Liquid Glass More button
    /// morphs into the node actions popover.
    /// - During the morph, the More bar item disappears from the toolbar.
    ///   - The indicator would move rightwards to fill its position
    ///   - This pushes the More button, while it is still animating, towards
    ///     the screen edge, rather than toward the popover, which causes the
    ///     animation to look buggy.
    ///
    /// To fix the above, we hide the transfer indicator before the presentation
    /// begins, and show it again when the presentation finishes.
    private(set) var isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation = false

    @ObservationIgnored private let onMoreTapped: PDFViewerMoreMenuDependencies.OnMoreTapped?

    init(onMoreTapped: PDFViewerMoreMenuDependencies.OnMoreTapped?) {
        self.onMoreTapped = onMoreTapped
    }

    func showsMoreButton(isDocumentLoadFailed: Bool) -> Bool {
        onMoreTapped != nil && !isDocumentLoadFailed
    }

    func didTapMore() {
        onMoreTapped?(nil)
    }

    func didTapMoreBarItem(isInFullScreenWindow: Bool) {
        // Only a full-screen iPad window presents the popover the bar item
        // morphs into; Split View and Slide Over get a sheet.
        guard isInFullScreenWindow else { return didTapMore() }
        guard let onMoreTapped else { return }

        isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation = true
        onMoreTapped { [weak self] in
            self?.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation = false
        }
    }
}
