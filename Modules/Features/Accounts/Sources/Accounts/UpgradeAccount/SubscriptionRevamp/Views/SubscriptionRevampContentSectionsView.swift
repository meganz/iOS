import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import SwiftUI

/// The section stack shared by both redesigned subscription pages: Pro features,
/// current plan, billing cycle picker, plan cards, benefits, the optional free
/// plan card, the subscription details disclosure and the legal footer.
///
/// The standard and promo pages differ only in their header and intro; everything
/// from the features list downward lives here.
struct SubscriptionContentSectionsView: View {
    let dependency: RevampUpgradePlansDependency
    @ObservedObject var viewModel: UpgradePlansViewModel
    let purchaseViewModel: PlanPurchaseViewModel
    let externalPurchaseViewModel: ExternalPurchaseViewModel?
    let dismiss: (UpgradePlansDismissReason) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SubscriptionProFeaturesView(viewModel: .init(plans: viewModel.plans))
                .padding(.top, TokenSpacing._3)
            if let currentPlan = viewModel.currentPlanViewModel {
                SubscriptionCurrentPlanView(viewModel: currentPlan)
                    .padding(.top, TokenSpacing._3)
                if viewModel.isOnHighestPlan {
                    pricingPageHint
                        .padding(.top, TokenSpacing._3)
                }
            }
            cyclePicker
                .padding(.top, TokenSpacing._3)
            SubscriptionPlanCardsView(
                cards: viewModel.planCards(for: viewModel.selectedCycle),
                purchaseViewModel: purchaseViewModel,
                externalPurchaseViewModel: externalPurchaseViewModel
            )
            .padding(.top, TokenSpacing._3)
            SubscriptionBenefitsListView()
                .padding(.top, TokenSpacing._4)
            if let freePlanCard = viewModel.freePlanCard {
                SubscriptionFreePlanCardView(model: freePlanCard, dismiss: dismiss)
                    .padding(.vertical, TokenSpacing._5)
            }
            SubscriptionDetailsView()
                .padding(.top, TokenSpacing._5)
            SubscriptionLegalFooterView(dependency: dependency)
                .padding(.top, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._13)
        }
    }

    /// Points users already on the top plan at the web pricing page, the only place
    /// left to upgrade further.
    private var pricingPageHint: some View {
        TextWithLinkView(details: pricingPageDetails)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .tint(TokenColors.Link.primary.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pricingPageDetails: TextWithLinkDetails {
        let fullText = Strings.Localizable.UpgradeAccountPlan.Footer.Message.pricingPage
        let tappableText = fullText.subString(from: "[A]", to: "[/A]") ?? ""
        let fullTextWithoutFormatters = fullText
            .replacingOccurrences(of: "[A]", with: "")
            .replacingOccurrences(of: "[/A]", with: "")
        return TextWithLinkDetails(fullText: fullTextWithoutFormatters,
                                   tappableText: tappableText,
                                   linkString: "https://\(dependency.domainName)/pro",
                                   textColor: TokenColors.Text.primary.swiftUI,
                                   linkColor: TokenColors.Link.primary.swiftUI)
    }

    private var cyclePicker: some View {
        SubscriptionCyclePickerView(
            dependency: .init(
                plans: viewModel.plans,
                featuredPlan: viewModel.featuredPlan,
                currentPlan: viewModel.currentPlan,
                tracker: dependency.analyticsUseCase
            ),
            selection: $viewModel.selectedCycle
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, TokenSpacing._7)
        .padding(.bottom, TokenSpacing._4)
    }
}
