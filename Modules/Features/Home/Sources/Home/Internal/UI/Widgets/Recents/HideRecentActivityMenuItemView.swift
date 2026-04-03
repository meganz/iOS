import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct HideRecentActivityMenuItemView: View {
    let action: @MainActor () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text(Strings.Localizable.Settings.UserInterface.hideRecentActivity)
            } icon: {
                MEGAAssets.Image.eyeOff
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            }
        }
    }
}
