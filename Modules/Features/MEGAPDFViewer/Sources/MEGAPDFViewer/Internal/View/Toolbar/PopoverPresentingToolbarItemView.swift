import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI
import UIKit

@available(iOS 26.0, *)
struct PopoverPresentingToolbarItemView: UIViewRepresentable {
    let icon: UIImage
    let accessibilityLabel: String
    let onTap: @MainActor (_ isInFullScreenWindow: Bool) -> Void
    let onReadyForPopoverMenuPresentation: @MainActor (UIBarButtonItem) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            icon: icon,
            accessibilityLabel: accessibilityLabel,
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
            icon: UIImage,
            accessibilityLabel: String,
            onTap: @escaping (Bool) -> Void,
            onReadyForPopoverMenuPresentation: @escaping (UIBarButtonItem) -> Void
        ) {
            self.onTap = onTap
            self.onReadyForPopoverMenuPresentation = onReadyForPopoverMenuPresentation
            item = UIBarButtonItem(
                image: icon,
                style: .plain,
                target: nil,
                action: nil
            )
            item.hidesSharedBackground = true
            super.init()
            item.target = self
            item.action = #selector(tapped)
            item.accessibilityLabel = accessibilityLabel
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
