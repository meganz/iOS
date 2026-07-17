import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// The promo redesigned subscription page.
///
/// A promo banner with a fade-out gradient, the promo hero card, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionRevampPromoView: View {

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let dependency: RevampUpgradePlansDependency
    private let viewModel: RevampUpgradePlansViewModel

    init(
        dependency: RevampUpgradePlansDependency,
        viewModel: RevampUpgradePlansViewModel
    ) {
        self.viewModel = viewModel
        self.dependency = dependency
    }

    public init(dependency: RevampUpgradePlansDependency) {
        self.init(dependency: dependency, viewModel: .promo)
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
                SubscriptionRevampContentSectionsView(dependency: dependency, viewModel: viewModel)
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
            .subscriptionHeaderBottomFade()
    }

    @ViewBuilder
    private var promoHero: some View {
        if let promoHeader = viewModel.promoHeader {
            SubscriptionPromoHeaderView(model: promoHeader)
                .blendIntoHeader(offset: TokenSpacing._16, isCompact: verticalSizeClass == .compact)
        }
    }

    @ViewBuilder
    private var highlightedPlanCard: some View {
        if let card = viewModel.highlightedPlanCard {
            PlanCardContainer(cardBackgroundColor: .highlightedPlanCardColor) {
                PlanCardRibbon(
                    text: card.ribbonText,
                    fill: TokenColors.Button.brand.swiftUI,
                    foreground: TokenColors.Text.onColor.swiftUI
                )
            } content: {
                VStack(alignment: .leading, spacing: TokenSpacing._4) {
                    PlanTitleView(card.title)
                    PlanPriceView(.discountMonthly(.init( // [IOS-12185]: Feed the correct PlanPrice to the higlighed plan
                        originalPrice: card.originalPrice,
                        discountedPrice: card.discountedPrice,
                        billingCaption: card.priceDescription
                    )))
                    PlanFeatureListView {
                        PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: card.storage)
                        PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: card.transfer)
                    }
                    Button(card.buttonTitle, action: {
                        // [IOS-12185]: Handle buy action
                    })
                        .buttonStyle(BrandButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, TokenSpacing._2)
        }
    }
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
