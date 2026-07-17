import MEGADesignToken
import MEGADomain
import SwiftUI

/// The section stack shared by both redesigned subscription pages: Pro features,
/// current plan, billing cycle picker, plan cards, benefits, the optional free
/// plan card, the subscription details disclosure and the legal footer.
///
/// The standard and promo pages differ only in their header and intro; everything
/// from the features list downward lives here.
struct SubscriptionRevampContentSectionsView: View {
    let dependency: RevampUpgradePlansDependency
    let viewModel: RevampUpgradePlansViewModel

    @State private var selectedCycle: SubscriptionCycleEntity = .yearly

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SubscriptionProFeaturesView()
                .padding(.top, TokenSpacing._3)
            SubscriptionCurrentPlanView(viewModel: viewModel.currentPlan)
                .padding(.top, TokenSpacing._3)
            cyclePicker
                .padding(.top, TokenSpacing._3)
            SubscriptionPlanCardsView()
                .padding(.top, TokenSpacing._3)
            SubscriptionBenefitsListView()
                .padding(.top, TokenSpacing._3)
                .padding(.top, TokenSpacing._2)
            if let freePlanCard = viewModel.freePlanCard {
                SubscriptionFreePlanCardView(model: freePlanCard)
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
            options: SubscriptionRevampMockData.cycleOptions,
            selection: $selectedCycle,
            title: SubscriptionRevampMockData.cycleTitle,
            savingText: SubscriptionRevampMockData.savingText
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, TokenSpacing._7)
        .padding(.bottom, TokenSpacing._4)
    }
}
