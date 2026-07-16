import MEGADesignToken
import MEGAL10n
import SwiftUI

/// The renewal notice and legal links shown at the bottom of the redesigned
/// subscription pages. Shared by the promo and standard pages.
struct SubscriptionLegalFooterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            Button {
                // [IOS-12185]: Wire restore purchase flow (App Store mandatory)
            } label: {
                Text(Strings.Localizable.UpgradeAccountPlan.Button.Restore.title)
                    .font(.footnote.bold())
                    .foregroundStyle(TokenColors.Link.primary.swiftUI)
            }

            Button {
                // [IOS-12185]: Wire terms and policies navigation
            } label: {
                Text(Strings.Localizable.Settings.Section.termsAndPolicies)
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
