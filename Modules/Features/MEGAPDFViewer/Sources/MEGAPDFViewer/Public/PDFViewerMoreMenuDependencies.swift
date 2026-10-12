import UIKit

public struct PDFViewerMoreMenuDependencies {
    public typealias OnMoreAnimationCompletion = @MainActor () -> Void
    public typealias OnMoreTapped = @MainActor (OnMoreAnimationCompletion?) -> Void

    public struct FullScreenIPadMorePopoverAnchorReadyCallbacks {
        /// iOS 18 and below default. The position of the view passed into this
        /// closure can be used to target the iPad node actions popover's arrow.
        let onMoreAnchorReadyForMenuPresentation: @MainActor (UIView) -> Void
        /// iOS 26+ default
        let onMoreBarItemReadyForMenuPresentation: @MainActor (UIBarButtonItem) -> Void

        public init(
            onMoreAnchorReadyForMenuPresentation: @escaping @MainActor (UIView) -> Void,
            onMoreBarItemReadyForMenuPresentation: @escaping @MainActor (UIBarButtonItem) -> Void
        ) {
            self.onMoreAnchorReadyForMenuPresentation = onMoreAnchorReadyForMenuPresentation
            self.onMoreBarItemReadyForMenuPresentation = onMoreBarItemReadyForMenuPresentation
        }
    }

    /// Invoked when ••• is tapped.
    let onMoreTapped: OnMoreTapped
    let fullScreenIPadMorePopoverAnchorReadyCallbacks: FullScreenIPadMorePopoverAnchorReadyCallbacks

    public init(
        onMoreTapped: @escaping OnMoreTapped,
        fullScreenIPadMorePopoverAnchorReadyCallbacks: FullScreenIPadMorePopoverAnchorReadyCallbacks
    ) {
        self.onMoreTapped = onMoreTapped
        self.fullScreenIPadMorePopoverAnchorReadyCallbacks = fullScreenIPadMorePopoverAnchorReadyCallbacks
    }
}
