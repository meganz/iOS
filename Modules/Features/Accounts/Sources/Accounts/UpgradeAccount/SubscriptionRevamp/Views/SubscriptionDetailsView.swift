import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// The fixed "Subscription details" auto-renewal disclosure shown near the
/// bottom of both redesigned subscription pages.
struct SubscriptionDetailsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            TextWithLinkView(details: autoRenewDescription)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .tint(TokenColors.Link.primary.swiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        Strings.Localizable.UpgradeAccountPlan.Header.Title.subscriptionDetails
    }

    private var autoRenewDescription: TextWithLinkDetails {
        let fullText = Strings.Localizable.SubscriptionPurchase.autoRenewDescription
        let tappableText = fullText.subString(from: "[L]", to: "[/L]") ?? ""
        let fullTextWithoutFormatters = fullText
            .replacingOccurrences(of: "[L]", with: "")
            .replacingOccurrences(of: "[/L]", with: "")
        return TextWithLinkDetails(fullText: fullTextWithoutFormatters,
                                   tappableText: tappableText,
                                   linkString: "https://support.apple.com/118428",
                                   textColor: TokenColors.Text.secondary.swiftUI,
                                   linkColor: TokenColors.Link.primary.swiftUI)
    }
}

#Preview {
    SubscriptionDetailsView()
        .padding()
}
