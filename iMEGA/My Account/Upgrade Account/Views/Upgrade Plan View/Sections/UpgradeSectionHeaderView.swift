import SwiftUI

struct UpgradeSectionHeaderView: View {
    var currentPlanName: String
    @Binding var selectedTermIndex: Int
    
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
            
            Picker("Account Plan Term", selection: $selectedTermIndex) {
                Text(Strings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.monthly).tag(0)
                Text(Strings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.yearly).tag(1)
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
