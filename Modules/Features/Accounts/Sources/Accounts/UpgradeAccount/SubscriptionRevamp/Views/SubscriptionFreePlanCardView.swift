import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// The optional "Get started with our free plan" card: a headline, two feature
/// rows and a secondary call to action, in the shared plan card container.
struct SubscriptionFreePlanCardView: View {
    let model: SubscriptionFreePlanCardModel

    var body: some View {
        PlanCardContainer {
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                header
                featureRows
                MEGAButton(
                    model.primaryButtonTitle,
                    type: .secondary,
                    action: {} // [IOS-12185]: Wire the free plan onboarding flow
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            Text(model.cardTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(model.storageTitle)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var featureRows: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._2) {
            featureRow(icon: MEGAAssets.Image.monoCloudMediumThinOutline, title: model.storageTitle)
            featureRow(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, title: model.transferTitle)
        }
    }

    private func featureRow(icon: Image, title: String) -> some View {
        HStack(alignment: .center, spacing: TokenSpacing._5) {
            icon
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.brand.swiftUI)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, TokenSpacing._2)
    }
}

#Preview {
    SubscriptionFreePlanCardView(model: SubscriptionRevampMockData.freePlanCard)
        .padding()
}
