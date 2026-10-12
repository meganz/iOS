import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI
import UIKit

/// Wraps one More `UIBarButtonItem` in a `UIToolbar` for SwiftUI, to allow the
/// More button to morph into the node actions popover on Liquid Glass iPad.
///
/// When presenting the More menu, the wrapped `UIBarButtonItem` will be
/// provided to `ActionSheetViewController.configurePresentationStyle`.
/// The latter will use the More button (inside the bar item) as the source UI
/// element of the Liquid Glass popover animation on iPad.
@available(iOS 26.0, *)
struct PDFViewerMoreToolbarItemView: UIViewRepresentable {
    let onTap: @MainActor (_ isInFullScreenWindow: Bool) -> Void
    let onReadyForPopoverMenuPresentation: @MainActor (UIBarButtonItem) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTap: onTap,
            onReadyForPopoverMenuPresentation: onReadyForPopoverMenuPresentation
        )
    }

    func makeUIView(context: Context) -> UIToolbar {
        let toolbar = UIToolbar()
        let appearance = UIToolbarAppearance()
        appearance.configureWithTransparentBackground()
        toolbar.standardAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        toolbar.tintColor = TokenColors.Icon.primary
        toolbar.setItems([context.coordinator.item], animated: false)
        context.coordinator.toolbar = toolbar
        return toolbar
    }

    func updateUIView(_ uiView: UIToolbar, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onReadyForPopoverMenuPresentation = onReadyForPopoverMenuPresentation
        context.coordinator.reportReadyForPopoverMenuPresentation()
    }

    @MainActor
    final class Coordinator: NSObject {
        var onTap: (Bool) -> Void
        var onReadyForPopoverMenuPresentation: (UIBarButtonItem) -> Void
        weak var toolbar: UIToolbar?

        let item: UIBarButtonItem

        init(
            onTap: @escaping (Bool) -> Void,
            onReadyForPopoverMenuPresentation: @escaping (UIBarButtonItem) -> Void
        ) {
            self.onTap = onTap
            self.onReadyForPopoverMenuPresentation = onReadyForPopoverMenuPresentation
            item = UIBarButtonItem(
                image: MEGAAssets.UIImage.monoMoreHorizontalMediumThinOutline,
                style: .plain,
                target: nil,
                action: nil
            )
            item.hidesSharedBackground = true
            super.init()
            item.target = self
            item.action = #selector(tapped)
            item.accessibilityLabel = Strings.Localizable.more
        }

        func reportReadyForPopoverMenuPresentation() {
            // Defer to next run loop, as this method is primarily triggered
            // from a SwiftUI update, specifically `updateUIView:`
            Task { @MainActor [weak self] in
                guard let self else { return }
                onReadyForPopoverMenuPresentation(item)
            }
        }

        @objc private func tapped() {
            // Same check as `UIApplication.isSplitOrSlideOver`, which
            // `ActionSheetViewController` uses to choose a popover.
            guard let window = toolbar?.window,
                  let screen = window.windowScene?.screen else {
                return onTap(false)
            }
            onTap(window.frame.equalTo(screen.bounds))
        }
    }
}
