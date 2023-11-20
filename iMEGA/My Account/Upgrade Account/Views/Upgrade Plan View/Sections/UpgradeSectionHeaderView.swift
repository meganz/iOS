import Accounts
import MEGADomain
import MEGAL10n
import SwiftUI

struct UpgradeSectionHeaderView: View {
    var currentPlanName: String
    @Binding var selectedCycleTab: SubscriptionCycleEntity
    
    var body: some View {
        Section {
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.choosePlan)
                .font(.title3)
                .bold()
            
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.currentPlan(currentPlanName))
                .foregroundColor(.gray)
                .font(.subheadline)
                .bold()
                .padding(.top, 1)
            
            AccountPlanCyclePickerView(selectedCycleTab: $selectedCycleTab)
        }
    }
}
