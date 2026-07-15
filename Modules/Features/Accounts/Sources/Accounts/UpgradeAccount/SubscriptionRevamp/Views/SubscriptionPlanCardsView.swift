import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// Renders the list of ``SubscriptionPlanCardModel`` variants; shared by the promo and standard pages.
struct SubscriptionPlanCardsView: View {
    private let viewModel: SubscriptionPlanCardsViewModel

    init(viewModel: SubscriptionPlanCardsViewModel = SubscriptionPlanCardsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: TokenSpacing._4) {
            ForEach(viewModel.cards) { card in
                planCard(card)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func planCard(_ card: SubscriptionPlanCardModel) -> some View {
        if let ribbonText = card.ribbonText {
            PlanCardContainer {
                PlanCardRibbon(
                    text: ribbonText,
                    fill: TokenColors.Button.brand.swiftUI,
                    foreground: TokenColors.Text.onColor.swiftUI
                )
            } content: {
                cardContent(card)
            }
        } else {
            PlanCardContainer {
                cardContent(card)
            }
        }
    }

    private func cardContent(_ card: SubscriptionPlanCardModel) -> some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            PlanTitleView(card.title)
            PlanPriceView(planPrice(card.price))
            PlanFeatureListView {
                PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: card.storage)
                PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: card.transfer)
            }
            MEGAButton("Get \(card.title)", type: card.isPrimaryAction ? .primary : .secondary, action: {}) // To be localized later
        }
    }

    private func planPrice(_ price: SubscriptionPlanCardModel.Price) -> PlanPrice {
        switch price {
        case let .monthly(price):
            .monthly(price: price)
        case let .yearly(price, billing):
            .yearly(price: price, billing: billing)
        case let .discount(originalPrice, discountedPrice, description):
            .discount(originalPrice: originalPrice, discountedPrice: discountedPrice, description: description)
        }
    }
}

#Preview {
    ScrollView {
        SubscriptionPlanCardsView()
            .padding()
    }
}
