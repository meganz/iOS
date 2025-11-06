import MEGASwiftUI
import SwiftUI

public struct PlanHeaderView: View {
    public var viewModel: AccountPlanViewModel
    public var foregroundSelectedColor: Color
    public var foregroundUnSelectedColor: Color
    public var backgroundColor: Color
    public var strokeColor: Color
    public var currentPlanTagColor: Color
    public var recommendedPlanTagColor: Color
    
    public var body: some View {
        HStack {
            Text(viewModel.plan.name)
                .font(.headline)
            
            PlanHeaderTagView(
                plan: viewModel.plan,
                planTag: viewModel.planTag,
                currentPlanTagColor: currentPlanTagColor,
                recommendedPlanTagColor: recommendedPlanTagColor
            )

            Spacer()
            
            if viewModel.isSelectionEnabled {
                CheckMarkView(
                    markedSelected: viewModel.isSelected,
                    foregroundColor: viewModel.isSelected ? foregroundSelectedColor: foregroundUnSelectedColor,
                    showBorder: false
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(strokeColor, lineWidth: 0.5)
        )
    }
}
