import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchaseHeaderView: View {
    let showBackButton: Bool
    let dismissAction: () -> Void

    var body: some View {
        HStack {
            Button {
                dismissAction()
            } label: {
                MEGAAssets.Image.arrowLeftMediumOutline
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .frame(width: 32, height: 32)
                    .background(TokenColors.Button.secondary.swiftUI)
                    .cornerRadius(TokenSpacing._3)
            }
            .opacity(showBackButton ? 1 : 0)
            
            Spacer()
            
            Button {
                dismissAction()
            } label: {
                Text(Strings.Localizable.SubscriptionPurchase.maybeLater)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .padding(.vertical, TokenSpacing._2)
                    .padding(.horizontal, TokenSpacing._4)
                    .background(TokenColors.Background.surface1.swiftUI)
                    .cornerRadius(TokenSpacing._3)
            }
            .opacity(showBackButton ? 0 : 1)
            
        }
        .frame(height: 52)
        .padding(.horizontal, TokenSpacing._5)
    }
}
