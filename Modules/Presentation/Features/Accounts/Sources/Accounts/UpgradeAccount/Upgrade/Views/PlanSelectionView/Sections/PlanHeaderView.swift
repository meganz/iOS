import MEGASwiftUI
import SwiftUI

public struct PlanHeaderView: View {
    public var viewModel: AccountPlanViewModel
    public var foregroundSelectedColor: Color
    public var foregroundUnSelectedColor: Color
    public var backgroundColor: Color
    public var strokeColor: Color
    public var currentPlanTagColor: Color
    public var recommededPlanTagColor: Color
    
    public var body: some View {
        HStack {
            Text(viewModel.plan.name)
                .font(.headline)
            
            PlanHeaderTagView(planTag: viewModel.planTag,
                              currentPlanTagColor: currentPlanTagColor,
                              recommededPlanTagColor: recommededPlanTagColor)
            
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
