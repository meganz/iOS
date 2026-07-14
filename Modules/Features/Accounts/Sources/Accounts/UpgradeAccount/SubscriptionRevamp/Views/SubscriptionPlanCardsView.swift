import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// Currently this is just a mock content exercising the three ``PlanPrice`` variants; shared by the
/// promo and standard pages. The actual data will be fed in subsequent MR
struct SubscriptionPlanCardsView: View { // [IOS-12185]: Implement real data with proper view model
    var body: some View {
        VStack(spacing: TokenSpacing._4) {
            PlanCardContainer {
                PlanCardRibbon(
                    text: "Best value",
                    fill: TokenColors.Button.brand.swiftUI,
                    foreground: TokenColors.Text.onColor.swiftUI
                )
            } content: {
                card(
                    title: "Pro Lite",
                    price: .yearly(price: "€3.33/month", billing: "€40.01 charged yearly"),
                    storage: "400 GB storage",
                    transfer: "1 TB transfer",
                    buttonType: .primary
                )
            }

            PlanCardContainer {
                card(
                    title: "Pro I",
                    price: .monthly(price: "€9.99/month"),
                    storage: "2 TB storage",
                    transfer: "2 TB transfer"
                )
            }

            PlanCardContainer {
                card(
                    title: "Pro II",
                    price: .discount(
                        originalPrice: "€19.99",
                        discountedPrice: "€14.99/month",
                        description: "Discount price for the first 12 months"
                    ),
                    storage: "8 TB storage",
                    transfer: "8 TB transfer"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func card(
        title: String,
        price: PlanPrice,
        storage: String,
        transfer: String,
        buttonType: MEGAButtonType = .secondary
    ) -> some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            PlanTitleView(title)
            PlanPriceView(price)
            PlanFeatureListView {
                PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: storage)
                PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: transfer)
            }
            MEGAButton("Get \(title)", type: buttonType, action: {}) // To be localized later
        }
    }
}

#Preview {
    ScrollView {
        SubscriptionPlanCardsView()
            .padding()
    }
}
