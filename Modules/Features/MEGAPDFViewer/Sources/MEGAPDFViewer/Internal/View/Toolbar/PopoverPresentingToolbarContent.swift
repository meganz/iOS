import SwiftUI
import UIKit

struct PopoverPresentingToolbarContent: ToolbarContent {
    enum PresentationPolicy {
        case moreMenu
        case activity

        func shouldMorph(
            isIPad: Bool,
            isLiquidGlass: Bool,
            isInFullScreenWindow: Bool
        ) -> Bool {
            isIPad && isLiquidGlass && (self == .activity || isInFullScreenWindow)
        }
    }

    private let onTap: @MainActor (Bool) -> Void
    private let icon: UIImage
    private let accessibilityLabel: String
    private let anchorReadyCallbacks: PDFViewerTrailingPopoverDependencies.AnchorReadyCallbacks?
    private let presentationPolicy: PresentationPolicy

    init(
        icon: UIImage,
        accessibilityLabel: String,
        onTap: @escaping @MainActor (Bool) -> Void,
        anchorReadyCallbacks: PDFViewerTrailingPopoverDependencies.AnchorReadyCallbacks?,
        presentationPolicy: PresentationPolicy
    ) {
        self.onTap = onTap
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.anchorReadyCallbacks = anchorReadyCallbacks
        self.presentationPolicy = presentationPolicy
    }

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if #available(iOS 26.0, *),
               UIDevice.current.userInterfaceIdiom == .pad,
               let anchorReadyCallbacks {
                PopoverPresentingToolbarItemView(
                    icon: icon,
                    accessibilityLabel: accessibilityLabel,
                    onTap: { isFullScreen in
                        onTap(presentationPolicy.shouldMorph(
                            isIPad: true, isLiquidGlass: true,
                            isInFullScreenWindow: isFullScreen
                        ))
                    },
                    onReadyForPopoverMenuPresentation: anchorReadyCallbacks.onBarItemReady
                )
                .frame(width: 36, height: 44)
            } else {
                Button {
                    onTap(false)
                } label: {
                    Image(uiImage: icon)
                }
                .background {
                    if let anchorReadyCallbacks {
                        PopoverPresentingToolbarAnchorView(onReady: anchorReadyCallbacks.onViewReady)
                    }
                }
                .accessibilityLabel(accessibilityLabel)
            }
        }
    }
}
