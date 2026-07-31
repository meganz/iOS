import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// Renders the list of ``SubscriptionPlanCardModel`` variants; shared by the promo and standard pages.
struct SubscriptionPlanCardsView: View {
    let cards: [SubscriptionPlanCardModel]

    var body: some View {
        VStack(spacing: TokenSpacing._4) {
            ForEach(cards) { card in
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
            PlanPriceView(card.price)
            PlanFeatureListView {
                PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: card.storage)
                PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: card.transfer)
            }
            buyButton(card)
        }
    }

    @ViewBuilder
    private func buyButton(_ card: SubscriptionPlanCardModel) -> some View {
        let title = Strings.Localizable.SubscriptionPurchase.Button.getPlan(card.title)
        if card.hasOffer {
            BrandButton(title: title) {
                // [IOS-12185]: Handle buy action
            }
        } else {
            MEGAButton(
                title,
                type: card.isPrimaryAction ? .primary : .secondary,
                action: {
                    // [IOS-12185]: Handle buy action
                }
            )
        }
    }
}

#Preview {
    ScrollView {
        SubscriptionPlanCardsView(cards: SubscriptionRevampMockData.planCards)
            .padding()
    }
}
