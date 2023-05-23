import SwiftUI

struct UpgradeSectionHeaderView: View {
    var currentPlanName: String
    @Binding var selectedTermIndex: Int
    
    var body: some View {
        Section {
            Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Header.Title.choosePlan)
                .font(.title3)
                .bold()
            
            Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Header.Title.currentPlan(currentPlanName))
                .foregroundColor(.gray)
                .font(.subheadline)
                .bold()
                .padding(.top, 1)
            
            Picker("Account Plan Term", selection: $selectedTermIndex) {
                Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.monthly).tag(0)
                Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Header.PlanTermPicker.yearly).tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.top)
            
            Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Header.Title.saveYearlyBilling)
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
