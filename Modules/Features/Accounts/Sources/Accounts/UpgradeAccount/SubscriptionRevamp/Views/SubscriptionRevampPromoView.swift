import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAUIComponent
import SwiftUI

/// The promo redesigned subscription page.
///
/// A promo banner with a fade-out gradient, the promo hero card, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionRevampPromoView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let viewModel: SubscriptionRevampPromoViewModel

    init(viewModel: SubscriptionRevampPromoViewModel) {
        self.viewModel = viewModel
    }

    public init() {
        self.init(viewModel: SubscriptionRevampPromoViewModel())
    }

    public var body: some View {
        SubscriptionRevampBaseView(
            compactHeaderImage: MEGAAssets.Image.promoBanner
            , regularHeader: {
                promoBanner
            }, content: {
                promoHero
                highlightedPlanCard
                    .padding(.vertical, TokenSpacing._4)
                SubscriptionProFeaturesView(features: viewModel.features)
                    .padding(.top, TokenSpacing._3)
                SubscriptionCurrentPlanView(viewModel: viewModel.currentPlan)
                    .padding(.top, TokenSpacing._3)
                SubscriptionPlanCardsView()
                    .padding(.top, TokenSpacing._3)
                SubscriptionBenefitsListView(benefits: viewModel.benefits)
                    .padding(.top, TokenSpacing._3)
                SubscriptionLegalFooterView()
                    .padding(.bottom, TokenSpacing._13)
            }
        )
    }

    private var promoBanner: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .overlay(alignment: .top) {
                MEGAAssets.Image.promoBannerCentered
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: TokenColors.Background.page.swiftUI, location: 0.6),
                        .init(color: TokenColors.Background.page.swiftUI, location: 1.0)
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
                .frame(height: 120)
            }
    }

    private var promoHero: some View {
        SubscriptionPromoHeaderView(model: viewModel.promoHeader)
            .padding(.top, verticalSizeClass != .compact ? -TokenSpacing._16 : 0) // In non-compact mode, the title needs to blend into the header to achieve the designated UI
    }

    private var highlightedPlanCard: some View {
        let card = viewModel.highlightedPlanCard
        return PlanCardContainer(cardBackgroundColor: .highlightedPlanCardColor) {
            PlanCardRibbon(
                text: card.ribbonText,
                fill: TokenColors.Button.brand.swiftUI,
                foreground: TokenColors.Text.onColor.swiftUI
            )
        } content: {
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                PlanTitleView(card.title)
                PlanPriceView(.discountMonthly(.init(
                    originalPrice: card.originalPrice,
                    discountedPrice: card.discountedPrice,
                    billingCaption: card.priceDescription
                )))
                PlanFeatureListView {
                    PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: card.storage)
                    PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: card.transfer)
                }
                Button(card.buttonTitle, action: {})
                    .buttonStyle(BrandButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, TokenSpacing._2)
    }
}

#Preview {
    SubscriptionRevampPromoView()
}

private extension Color {
    // Custom background color for highlighted card, not defined by any token color
    static var highlightedPlanCardColor: Color {
        UIColor(
            dynamicProvider: {
                $0.userInterfaceStyle == .light
                ? UIColor.init(red: 253/255, green: 249/255, blue: 248/255, alpha: 1)
                    : UIColor(red: 35/255, green: 20/255, blue: 16/255, alpha: 1.0)
            }
        ).swiftUI

    }
}
