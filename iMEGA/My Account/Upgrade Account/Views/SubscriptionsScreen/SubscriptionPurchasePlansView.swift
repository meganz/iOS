import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchasePlansView: View {
    @ObservedObject var viewModel: UpgradeAccountPlanViewModel
    @State private var chipOptions: [SubscriptionPurchaseChipOption]
    @State private var selectedChip: SubscriptionPurchaseChipOption

    init(viewModel: UpgradeAccountPlanViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        let selectedChip: SubscriptionPurchaseChipOption = .init(title: Strings.Localizable.yearly) {
            viewModel.selectedCycleTab = .yearly
        }
        let chipOptions: [SubscriptionPurchaseChipOption] =  [
            .init(title: Strings.Localizable.monthly) { viewModel.selectedCycleTab = .monthly },
            selectedChip
        ]
        _chipOptions = State(initialValue: chipOptions)
        _selectedChip = State(initialValue: selectedChip)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._6) {
            SubscriptionPurchaseChipsSelectorView(options: chipOptions, selected: $selectedChip)
            savingView
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
}
