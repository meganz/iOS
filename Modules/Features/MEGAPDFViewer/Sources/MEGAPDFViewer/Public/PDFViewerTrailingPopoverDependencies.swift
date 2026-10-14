import UIKit

public struct PDFViewerTrailingPopoverDependencies {
    public typealias OnPresentationCompletion = @MainActor () -> Void
    public typealias OnTapped = @MainActor (OnPresentationCompletion?) -> Void

    public struct AnchorReadyCallbacks {
        let onViewReady: @MainActor (UIView) -> Void
        let onBarItemReady: @MainActor (UIBarButtonItem) -> Void

        public init(
            onViewReady: @escaping @MainActor (UIView) -> Void,
            onBarItemReady: @escaping @MainActor (UIBarButtonItem) -> Void
        ) {
            self.onViewReady = onViewReady
            self.onBarItemReady = onBarItemReady
        }
    }

    let onTapped: OnTapped
    let anchorReadyCallbacks: AnchorReadyCallbacks

    public init(
        onTapped: @escaping OnTapped,
        anchorReadyCallbacks: AnchorReadyCallbacks
    ) {
        self.onTapped = onTapped
        self.anchorReadyCallbacks = anchorReadyCallbacks
    }
}
