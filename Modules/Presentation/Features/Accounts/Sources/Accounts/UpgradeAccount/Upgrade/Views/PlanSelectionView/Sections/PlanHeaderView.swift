import MEGASwiftUI
import SwiftUI

public struct PlanHeaderView: View {
    public var viewModel: AccountPlanViewModel
    
    public var body: some View {
        HStack {
            Text(viewModel.plan.name)
                .font(.headline)
            
            PlanHeaderTagView(planTag: viewModel.planTag)
            
            Spacer()
            
            if viewModel.isSelectionEnabled {
                CheckMarkView(
                    markedSelected: viewModel.isSelected,
                    foregroundColor: viewModel.isSelected ? Color("turquoise") : Color("unselectedTint"),
                    showBorder: false
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color("headerBackground"))
        .overlay(
            Rectangle()
                .stroke(Color("borderTint"), lineWidth: 0.5)
        )
    }
}
