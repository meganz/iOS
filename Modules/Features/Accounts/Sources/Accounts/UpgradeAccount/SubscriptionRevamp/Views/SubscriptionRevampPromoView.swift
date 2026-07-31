import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// The promo redesigned subscription page.
///
/// A promo banner with a fade-out gradient, the promo hero card, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionPromoView: View {

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let dependency: RevampUpgradePlansDependency
    private let viewModel: UpgradePlansViewModel
    private let dismissAction: () -> Void

    init(
        dependency: RevampUpgradePlansDependency,
        viewModel: UpgradePlansViewModel,
        dismissAction: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.dependency = dependency
        self.dismissAction = dismissAction
    }

    public var body: some View {
        SubscriptionBaseView(
            compactHeaderImage: MEGAAssets.Image.promoBanner,
            closeButtonType: .init(viewType: dependency.viewType),
            dismissAction: dismissAction,
            regularHeader: {
                promoBanner
            }, content: {
                promoHero
                highlightedPlanCard
                    .padding(.vertical, TokenSpacing._4)
                SubscriptionContentSectionsView(dependency: dependency, viewModel: viewModel, dismissAction: dismissAction)
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
            SubscriptionPromoHeaderView(viewModel: promoHeader)
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
                    PlanPriceView(card.price)
                    PlanFeatureListView {
                        PlanFeatureView(icon: MEGAAssets.Image.monoCloudMediumThinOutline, text: card.storage)
                        PlanFeatureView(icon: MEGAAssets.Image.monoArrowUpDownMediumThinOutline, text: card.transfer)
                    }
                    BrandButton(title: card.buttonTitle) {
                        // [IOS-12185]: Handle buy action
                    }
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
