import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchaseHeaderView: View {
    let dismissAction: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button {
                dismissAction()
            } label: {
                Text(Strings.Localizable.SubscriptionPurchase.maybeLater)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .padding(.vertical, TokenSpacing._2)
                    .padding(.horizontal, TokenSpacing._4)
                    .background(TokenColors.Button.secondary.swiftUI)
                    .cornerRadius(TokenSpacing._3)
            }
        }
        .frame(height: 52)
        .padding(.horizontal, TokenSpacing._5)
    }
}
