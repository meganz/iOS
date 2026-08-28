import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// The fixed `Save to MEGA` button anchored above the bottom safe area, replacing the icon-only bottom
/// toolbar of the pre-revamp album link screen.
struct AlbumLinkAnchoredButtons: View {
    let isDisabled: Bool
    /// The window's bottom safe area, measured by `ImportAlbumView` where the navigation stack can still
    /// see it. It cannot be read here: `safeAreaInset` hands its content a region that already sits above
    /// the safe area, so the value would be zero by the time it reached this view.
    let bottomSafeAreaInset: CGFloat
    let action: () -> Void

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.Link.Button.saveToMega,
                    icon: MEGAAssets.Image.uploadToCloud,
                    type: .primary,
                    state: isDisabled ? .disabled : .default,
                    action: action
                )
            ]
        )
        .background(TokenColors.Background.page.swiftUI.ignoresSafeArea(edges: .bottom))
        .padding(.bottom, -bottomSafeAreaInset)
    }
}

#Preview {
    AlbumLinkAnchoredButtons(isDisabled: false, bottomSafeAreaInset: 0) {}
}

#Preview("Disabled") {
    AlbumLinkAnchoredButtons(isDisabled: true, bottomSafeAreaInset: 0) {}
}
