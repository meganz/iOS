import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
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
    let dismissAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SubscriptionProFeaturesView(viewModel: .init(plans: viewModel.plans))
                .padding(.top, TokenSpacing._3)
            if let currentPlan = viewModel.currentPlanViewModel {
                SubscriptionCurrentPlanView(viewModel: currentPlan)
                    .padding(.top, TokenSpacing._3)
            }
            cyclePicker
                .padding(.top, TokenSpacing._3)
            SubscriptionPlanCardsView(
                cards: viewModel.planCards(for: viewModel.selectedCycle),
                purchaseViewModel: purchaseViewModel
            )
            .padding(.top, TokenSpacing._3)
            SubscriptionBenefitsListView()
                .padding(.top, TokenSpacing._4)
            if let freePlanCard = viewModel.freePlanCard {
                SubscriptionFreePlanCardView(model: freePlanCard, action: dismissAction)
                    .padding(.vertical, TokenSpacing._5)
            }
            SubscriptionDetailsView()
                .padding(.top, TokenSpacing._5)
            SubscriptionLegalFooterView(dependency: dependency)
                .padding(.top, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._13)
        }
    }

    private var cyclePicker: some View {
        SubscriptionCyclePickerView(
            dependency: .init(plans: viewModel.plans),
            selection: $viewModel.selectedCycle
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, TokenSpacing._7)
        .padding(.bottom, TokenSpacing._4)
    }
}
