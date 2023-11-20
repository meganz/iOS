import SwiftUI

public struct AccountPlanView: View {
    private var viewModel: AccountPlanViewModel
    
    public init(viewModel: AccountPlanViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
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
        .background(Color("bodyBackground"))
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
        viewModel.isSelected ? Color("turquoise") : Color("borderTint")
    }
}
