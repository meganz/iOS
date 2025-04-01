import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

public struct AccountPlanCyclePickerView: View {
    @Binding private var selectedCycleTab: SubscriptionCycleEntity
    private let subMessageBackgroundColor: Color
    
    public init(selectedCycleTab: Binding<SubscriptionCycleEntity>, subMessageBackgroundColor: Color) {
        self._selectedCycleTab = selectedCycleTab
        self.subMessageBackgroundColor = subMessageBackgroundColor
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            Picker("Account Plan Cycle", selection: $selectedCycleTab) {
                Text(Strings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.monthly)
                    .tag(SubscriptionCycleEntity.monthly)
                Text(Strings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.yearly)
                    .tag(SubscriptionCycleEntity.yearly)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.top)
            
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.saveYearlyBilling)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(TokenColors.Text.success.swiftUI)
                .background(subMessageBackgroundColor)
                .cornerRadius(10)
                .padding(.bottom, 15)
        }
    }
}
