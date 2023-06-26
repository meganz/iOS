import MEGADomain
import SwiftUI

struct UpgradeSectionHeaderView: View {
    var currentPlanName: String
    @Binding var selectedTermTab: AccountPlanTermEntity
    
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
            
            Picker("Account Plan Term", selection: $selectedTermTab) {
                Text(Strings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.monthly)
                    .tag(AccountPlanTermEntity.monthly)
                Text(Strings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.yearly)
                    .tag(AccountPlanTermEntity.yearly)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.top)
            
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.saveYearlyBilling)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(Colors.UpgradeAccount.subMessageBackground.color))
                .cornerRadius(10)
                .padding(.bottom, 15)
        }
    }
}
