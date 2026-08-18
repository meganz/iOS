import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import SwiftUI

/// The promo redesigned subscription page.
///
/// A promo banner with a fade-out gradient, the promo hero card, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionPromoView: View {

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let dependency: RevampUpgradePlansDependency
    private let viewModel: UpgradePlansViewModel
    private let purchaseViewModel: PlanPurchaseViewModel
    private let externalPurchaseViewModel: ExternalPurchaseViewModel?
    private let dismiss: (UpgradePlansDismissReason) -> Void

    init(
        dependency: RevampUpgradePlansDependency,
        viewModel: UpgradePlansViewModel,
        purchaseViewModel: PlanPurchaseViewModel,
        externalPurchaseViewModel: ExternalPurchaseViewModel?,
        dismiss: @escaping (UpgradePlansDismissReason) -> Void
    ) {
        self.viewModel = viewModel
        self.dependency = dependency
        self.purchaseViewModel = purchaseViewModel
        self.externalPurchaseViewModel = externalPurchaseViewModel
        self.dismiss = dismiss
    }

    public var body: some View {
        SubscriptionBaseView(
            compactHeaderImage: MEGAAssets.Image.promoBanner,
            dependency: dependency,
            dismiss: dismiss,
            regularHeader: {
                promoBanner
            }, content: {
                promoHero
                highlightedPlanCard
                    .padding(.vertical, TokenSpacing._4)
                SubscriptionContentSectionsView(
                    dependency: dependency,
                    viewModel: viewModel,
                    purchaseViewModel: purchaseViewModel,
                    externalPurchaseViewModel: externalPurchaseViewModel,
                    dismiss: dismiss
                )
            }
        )
        .planPurchaseAlert(purchaseViewModel)
        .externalPurchaseAlert(externalPurchaseViewModel)
    }

    private var promoBanner: some View {
        SubscriptionPromoBannerView()
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
            SubscriptionPromoPlanCardView(card: card) {
                PlanPurchaseButton(
                    purchaseViewModel: purchaseViewModel,
                    title: card.buttonTitle,
                    productIdentifier: card.productIdentifier,
                    style: .brand
                )
            }
            .padding(.top, TokenSpacing._2)
        }
    }
}
