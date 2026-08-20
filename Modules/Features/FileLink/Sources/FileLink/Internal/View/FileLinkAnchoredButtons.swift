import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

extension EnvironmentValues {
    /// The window's bottom safe area, measured by `FileLinkView` where the navigation stack can still
    /// see it. The anchored buttons cannot read it themselves: `safeAreaInset` hands its content a region
    /// that already sits above the safe area, so the value there is zero.
    @Entry var fileLinkBottomSafeAreaInset: CGFloat = 0
}

/// The two fixed buttons anchored above the bottom safe area, offering the file's two main actions
/// without going through the more options sheet. The same pair the revamped folder link screen carries.
struct FileLinkAnchoredButtons: View {
    let isDisabled: Bool
    let onDownload: () -> Void
    let onSaveToMEGA: () -> Void

    @Environment(\.fileLinkBottomSafeAreaInset) private var bottomSafeAreaInset

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.download,
                    type: .secondary,
                    state: buttonState,
                    action: onDownload
                ),
                MEGAButton(
                    Strings.Localizable.Link.Button.saveToMega,
                    icon: MEGAAssets.Image.uploadToCloud,
                    type: .primary,
                    state: buttonState,
                    action: onSaveToMEGA
                )
            ],
            buttonsAlignment: .horizontal
        )
        // The backing reaches the bottom edge of the screen, so the home indicator strip below the
        // buttons shows page background rather than whatever the window puts behind the screen.
        .background(TokenColors.Background.page.swiftUI.ignoresSafeArea(edges: .bottom))
        // The design anchors the row to the bottom edge of the screen, with the component's own padding
        // as the only gap, while `safeAreaInset` places it above the home indicator strip and stacks that
        // padding on top. Cancelling the inset drops the row back down by exactly that strip.
        .padding(.bottom, -bottomSafeAreaInset)
    }

    private var buttonState: MEGAButtonState {
        isDisabled ? .disabled : .default
    }
}

#Preview {
    Color.clear
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FileLinkAnchoredButtons(isDisabled: false, onDownload: {}, onSaveToMEGA: {})
        }
}

#Preview("Disabled") {
    Color.clear
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FileLinkAnchoredButtons(isDisabled: true, onDownload: {}, onSaveToMEGA: {})
        }
}
