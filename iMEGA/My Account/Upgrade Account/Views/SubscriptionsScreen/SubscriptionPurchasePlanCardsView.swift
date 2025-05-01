import MEGADesignToken
import MEGADomain
import SwiftUI

struct SubscriptionPurchasePlanCardsView: View {
    @ObservedObject var viewModel: UpgradeAccountPlanViewModel

    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            ForEach(viewModel.filteredPlanList, id: \.self) { plan in
                SubscriptionPurchasePlanCardView(viewModel: viewModel.createAccountPlanViewModel(plan))
            }
        }
        .padding(.bottom, TokenSpacing._5)
    }
}
