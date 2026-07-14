import MEGADesignToken
import SwiftUI

/// The renewal notice and legal links shown at the bottom of the redesigned
/// subscription pages. Shared by the promo and standard pages.
struct SubscriptionLegalFooterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            Text("Subscriptions renew automatically. Cancel anytime in Settings.") // To be localized later
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)

            Button {} label: { // [IOS-12185]: Wire restore purchase flow (App Store mandatory)
                Text("Restore purchase") // To be localized later
                    .font(.footnote.bold())
                    .foregroundStyle(TokenColors.Link.primary.swiftUI)
            }

            Button {} label: { // [IOS-12185]: Wire terms and policies navigation
                Text("Terms and policies") // To be localized later
                    .font(.footnote.bold())
                    .foregroundStyle(TokenColors.Link.primary.swiftUI)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SubscriptionLegalFooterView()
        .padding()
}
