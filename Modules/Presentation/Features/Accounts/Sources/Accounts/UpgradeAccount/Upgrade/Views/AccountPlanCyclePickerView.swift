import MEGADomain
import MEGAL10n
import SwiftUI

public struct AccountPlanCyclePickerView: View {
    @Binding private var selectedCycleTab: SubscriptionCycleEntity
    
    public init(selectedCycleTab: Binding<SubscriptionCycleEntity>) {
        self._selectedCycleTab = selectedCycleTab
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
                .background(Color("subMessageBackground"))
                .cornerRadius(10)
                .padding(.bottom, 15)
        }
    }
}
