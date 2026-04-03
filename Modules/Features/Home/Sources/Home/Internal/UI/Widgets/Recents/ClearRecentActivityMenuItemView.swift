import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ClearRecentActivityMenuItemView: View {
    let action: @MainActor () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text(Strings.Localizable.Home.Recent.Menu.Action.clearRecentActivity)
            } icon: {
                MEGAAssets.Image.clearChatHistory
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            }
        }
        
    }
}

extension View {
    func confirmClearRecentActivityAlert(isPresented: Binding<Bool>, action: @MainActor @escaping () -> Void) -> some View {
        alert(
            Strings.Localizable.Home.Recent.Menu.Action.clearRecentActivity,
            isPresented: isPresented,
            actions: {
                Button(Strings.Localizable.dismiss, action: {})
                Button(Strings.Localizable.clear, action: action)
            },
            message: {
                Text(Strings.Localizable.Home.Recent.ClearRecentActivity.Alert.message)
            }
        )
    }
}
