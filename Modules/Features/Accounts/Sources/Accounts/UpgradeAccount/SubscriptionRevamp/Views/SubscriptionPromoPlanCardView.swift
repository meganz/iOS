import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// The featured (hero) promo plan card, shared by the promo subscription page and the promotional
/// offer landing dialog. The page passes its buy button as the `accessory`; the dialog anchors its
/// own to the bottom of the screen instead.
struct SubscriptionPromoPlanCardView<Accessory: View>: View {
    private let card: SubscriptionRevampPromoPlanCardModel
    private let accessory: Accessory

    init(
        card: SubscriptionRevampPromoPlanCardModel,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.card = card
        self.accessory = accessory()
    }

    var body: some View {
        PlanCardContainer(cardBackgroundColor: .highlightedPlanCardColor) {
            PlanCardRibbon(
                text: card.ribbonText,
                fill: TokenColors.Button.brand.swiftUI,
                foreground: TokenColors.Text.onColor.swiftUI
            )
        } content: {
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                PlanTitleView(card.title)
                PlanPriceView(card.price)
                PlanFeatureListView {
                    PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: card.storage)
                    PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: card.transfer)
                }
                accessory
            }
        }
        .frame(maxWidth: .infinity)
    }
}

extension SubscriptionPromoPlanCardView where Accessory == EmptyView {
    init(card: SubscriptionRevampPromoPlanCardModel) {
        self.init(card: card) { EmptyView() }
    }
}

private extension Color {
    // Custom background color for highlighted card, not defined by any token color
    static var highlightedPlanCardColor: Color {
        UIColor(
            dynamicProvider: {
                $0.userInterfaceStyle == .light
                ? UIColor(red: 253/255, green: 249/255, blue: 248/255, alpha: 1)
                : UIColor(red: 35/255, green: 20/255, blue: 16/255, alpha: 1)
            }
        ).swiftUI
    }
}
