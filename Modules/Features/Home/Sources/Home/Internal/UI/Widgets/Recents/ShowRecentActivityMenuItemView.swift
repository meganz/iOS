import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ShowRecentActivityMenuItemView: View {
    let action: @MainActor () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text(Strings.Localizable.Home.Recent.Menu.Action.showRecentActivity)
            } icon: {
                MEGAAssets.Image.eye
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            }
        }
    }
}
