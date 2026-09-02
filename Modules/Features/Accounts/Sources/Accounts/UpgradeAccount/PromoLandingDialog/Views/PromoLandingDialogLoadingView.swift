import MEGADesignToken
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

/// Skeleton loading state of the promotional offer landing dialog: the offer heading lines
/// followed by the single featured plan card, shimmering while the plans load.
struct PromoLandingDialogLoadingView: View {
    let dismissAction: @MainActor () -> Void

    private let fullWidthTitleLineCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._6) {
            titlePlaceholder
            SubscriptionPlanCardPlaceholderView()
        }
        .padding(.horizontal, TokenSpacing._5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .safeAreaInset(edge: .top, spacing: 0) {
            PromoLandingDialogCloseButton(dismissAction: dismissAction)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var titlePlaceholder: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            ForEach(0..<fullWidthTitleLineCount, id: \.self) { _ in
                SubscriptionPlaceholderLine()
                    .frame(maxWidth: .infinity)
            }
            SubscriptionPlaceholderLine()
                .frame(width: 123)
        }
        .shimmering()
    }
}

#Preview {
    PromoLandingDialogLoadingView(dismissAction: {})
}
