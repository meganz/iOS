import Accounts
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI

struct UpgradeSectionHeaderView: View {
    var currentPlanName: String
    @Binding var selectedCycleTab: SubscriptionCycleEntity
    var subMessageBackgroundColor: Color
    
    var body: some View {
        Section {
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.choosePlan)
                .font(.title3)
                .bold()
            
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.currentPlan(currentPlanName))
                .foregroundColor(TokenColors.Text.secondary.swiftUI)
                .font(.subheadline)
                .bold()
                .padding(.top, 1)
            
            AccountPlanCyclePickerView(selectedCycleTab: $selectedCycleTab, subMessageBackgroundColor: subMessageBackgroundColor)
        }
    }
}
