import MEGADesignToken
import MEGASwiftUI
import SwiftUI

/// The stand-in for a plan card, shared by the subscription page and the promotional offer landing dialog skeletons.
struct SubscriptionPlanCardPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            SubscriptionPlaceholderLine()
                .frame(width: 48)
            SubscriptionPlaceholderLine()
                .frame(width: 90)
            SubscriptionPlaceholderLine()
                .frame(width: 230)
            SubscriptionPlaceholderLine()
                .frame(width: 230)
            RoundedRectangle(cornerRadius: TokenRadius.small)
                .fill(SubscriptionPlaceholder.color)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shimmering()
        .padding(TokenSpacing._5)
        .background(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .fill(TokenColors.Background.page.swiftUI)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
        )
    }
}

#Preview {
    SubscriptionPlanCardPlaceholderView()
        .padding()
}
