import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// The two fixed buttons anchored above the bottom safe area, replacing the icon-only bottom
/// toolbar of the pre-revamp folder link screen.
extension EnvironmentValues {
    /// The window's bottom safe area, measured by `FolderLinkView` where the navigation stack can still
    /// see it. The anchored buttons cannot read it themselves: `safeAreaInset` hands its content a region
    /// that already sits above the safe area, so the value there is zero.
    @Entry var folderLinkBottomSafeAreaInset: CGFloat = 0

    /// Whether a mini player is docked below the anchored buttons — likewise invisible from inside the inset.
    @Entry var folderLinkMiniPlayerDocked: Bool = false
}

struct FolderLinkAnchoredButtons: View {
    @Binding var selection: FolderLinkBottomBarAction?
    let isDisabled: Bool

    @Environment(\.folderLinkBottomSafeAreaInset) private var bottomSafeAreaInset
    @Environment(\.folderLinkMiniPlayerDocked) private var isMiniPlayerDocked

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.download,
                    type: .secondary,
                    state: buttonState
                ) {
                    selection = .downloadToFiles
                },
                MEGAButton(
                    Strings.Localizable.Link.Button.saveToMega,
                    icon: MEGAAssets.Image.uploadToCloud,
                    type: .primary,
                    state: buttonState
                ) {
                    selection = .addToCloudDrive
                }
            ],
            buttonsAlignment: .horizontal
        )
        // The buttons float over the results list, so they need an opaque backing of their own. The
        // backing reaches the bottom edge of the screen so the home indicator strip below the buttons
        // does not show the list scrolling past underneath.
        .background(TokenColors.Background.page.swiftUI.ignoresSafeArea(edges: .bottom))
        // The design anchors the row to the bottom edge of the screen, with the component's own padding
        // as the only gap, while `safeAreaInset` places it above the home indicator strip and stacks that
        // padding on top. Cancelling the inset drops the row back down by exactly that strip.
        .padding(.bottom, bottomPadding)
    }

    private var bottomPadding: CGFloat {
        isMiniPlayerDocked ? 0 : -bottomSafeAreaInset
    }

    private var buttonState: MEGAButtonState {
        isDisabled ? .disabled : .default
    }
}

#Preview {
    FolderLinkAnchoredButtons(selection: .constant(nil), isDisabled: false)
}

#Preview("Disabled") {
    FolderLinkAnchoredButtons(selection: .constant(nil), isDisabled: true)
}
