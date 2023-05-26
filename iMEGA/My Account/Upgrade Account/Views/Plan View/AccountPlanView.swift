import SwiftUI

struct AccountPlanView: View {
    var viewModel: AccountPlanViewModel
    
    var body: some View {
        VStack {
            PlanHeaderView(viewModel: viewModel)
            
            HStack {
                PlanStorageView(plan: viewModel.plan)
                Spacer()
                PlanPricingView(plan: viewModel.plan)
            }
            .padding()
            .padding(.bottom, 5)
        }
        .background(Color(Colors.UpgradeAccount.Plan.bodyBackground.color))
        .overlay(
            roundedRectangle
                .stroke(borderColor, lineWidth: viewModel.isSelected ? 3 : 1.5)
        )
        .contentShape(roundedRectangle)
        .clipShape(roundedRectangle)
        .onTapGesture(perform: viewModel.didTapPlan)
    }
    
    private var roundedRectangle: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }
    
    private var borderColor: Color {
        viewModel.isSelected ? Color(Colors.Views.turquoise.color) : Color(Colors.UpgradeAccount.Plan.borderTint.color)
    }
}
