import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// The two fixed buttons anchored above the bottom safe area, replacing the icon-only bottom
/// toolbar of the pre-revamp folder link screen.
struct FolderLinkAnchoredButtons: View {
    @Binding var selection: FolderLinkBottomBarAction?
    let isDisabled: Bool

    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(
                    Strings.Localizable.download,
                    type: .secondary,
                    state: buttonState
                ) {
                    selection = .makeAvailableOffline
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
        // The buttons float over the results list, so they need an opaque backing of their own.
        .background(TokenColors.Background.page.swiftUI)
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
