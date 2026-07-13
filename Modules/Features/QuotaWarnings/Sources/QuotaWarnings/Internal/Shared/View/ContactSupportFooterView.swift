import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct ContactSupportFooterView: View {
    var body: some View {
        MEGABottomAnchoredButtons(
            buttons: [
                MEGAButton(Strings.Localizable.Accounts.CancelSubscriptionErrorAlert.Button.contactHelpdesk, type: .textOnly, action: {})
            ],
            allowMaxWidthForWideScreen: true
        )
    }
}

#Preview {
    ContactSupportFooterView()
}
