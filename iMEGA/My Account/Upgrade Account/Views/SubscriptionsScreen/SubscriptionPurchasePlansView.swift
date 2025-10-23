import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchasePlansView: View {
    @ObservedObject var viewModel: UpgradeAccountPlanViewModel

    init(viewModel: UpgradeAccountPlanViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._6) {
            SubscriptionPurchaseChipsSelectorView(
                options: viewModel.subscriptionPurchaseChipOptions,
                selected: $viewModel.selectedSubscriptionPurchaseChip)
            if viewModel.hasIntroductoryOffersToShow {
                savingViewWithIntroOffers
            } else {
                savingView
            }
            SubscriptionPurchasePlanCardsView(viewModel: viewModel)
        }
        .padding(.vertical, TokenSpacing._5)
    }

    private var savingView: some View {
        Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.saveYearlyBilling)
            .padding(.vertical, TokenSpacing._1)
            .padding(.horizontal, TokenSpacing._3)
            .foregroundStyle(TokenColors.Text.onColor.swiftUI)
            .font(.footnote.bold())
            .background(
                RoundedRectangle(cornerRadius: TokenRadius.small)
                    .fill(TokenColors.Button.brand.swiftUI)
            )
    }

    private var savingViewWithIntroOffers: some View {
        Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.saveYearlyBillingWithIntoOffer("16%"))
            .padding(.vertical, TokenSpacing._1)
            .padding(.horizontal, TokenSpacing._3)
            .foregroundStyle(TokenColors.Text.brand.swiftUI)
            .font(.footnote)
            .background(
                RoundedRectangle(cornerRadius: TokenRadius.small)
                    .stroke(TokenColors.Text.brand.swiftUI, lineWidth: 1)
            )
    }
}
