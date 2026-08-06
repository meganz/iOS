import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// Renders the list of ``SubscriptionPlanCardModel`` variants; shared by the promo and standard pages.
struct SubscriptionPlanCardsView: View {
    let cards: [SubscriptionPlanCardModel]
    let purchaseViewModel: PlanPurchaseViewModel
    /// `nil` when the website route is unavailable, in which case no card carries the button either.
    let externalPurchaseViewModel: ExternalPurchaseViewModel?

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
            externalPurchaseButton(card)
        }
    }

    private func buyButton(_ card: SubscriptionPlanCardModel) -> some View {
        PlanPurchaseButton(
            purchaseViewModel: purchaseViewModel,
            title: Strings.Localizable.SubscriptionPurchase.Button.getPlan(card.title),
            productIdentifier: card.productIdentifier,
            style: card.hasOffer ? .brand : .mega(card.isPrimaryAction ? .primary : .secondary)
        )
    }

    @ViewBuilder
    private func externalPurchaseButton(_ card: SubscriptionPlanCardModel) -> some View {
        if let externalPurchaseTitle = card.externalPurchaseTitle, let externalPurchaseViewModel {
            ExternalPurchaseButton(
                viewModel: externalPurchaseViewModel,
                title: externalPurchaseTitle,
                productIdentifier: card.productIdentifier
            )
        }
    }
}
