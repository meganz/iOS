import SwiftUI
import MEGASwiftUI

struct PlanHeaderView: View {
    var viewModel: AccountPlanViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.plan.name)
                .font(.headline)
            
            PlanHeaderTagView(planTag: viewModel.planTag)
            
            Spacer()
            
            if !viewModel.isCurrenPlan {
                CheckMarkView(
                    markedSelected: viewModel.isSelected,
                    foregroundColor: viewModel.isSelected ? Color(Colors.Views.turquoise.color) : Color(Colors.UpgradeAccount.Plan.unselectedTint.color),
                    showBorder: false
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color(Colors.UpgradeAccount.Plan.headerBackground.color))
        .overlay(
            Rectangle()
                .stroke(Color(Colors.UpgradeAccount.Plan.borderTint.color), lineWidth: 0.5)
        )
    }
}
