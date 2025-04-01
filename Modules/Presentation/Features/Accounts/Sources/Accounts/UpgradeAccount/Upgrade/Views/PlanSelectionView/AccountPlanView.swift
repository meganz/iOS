import MEGAAppPresentation
import MEGADesignToken
import SwiftUI

public struct AccountPlanView: View {
    private var viewModel: AccountPlanViewModel
    private let config: AccountsConfig
    
    public init(viewModel: AccountPlanViewModel,
                config: AccountsConfig) {
        self.viewModel = viewModel
        self.config = config
    }
    
    public var body: some View {
        VStack {
            PlanHeaderView(viewModel: viewModel,
                           foregroundSelectedColor: config.onboardingViewAssets.headerForegroundSelectedColor,
                           foregroundUnSelectedColor: config.onboardingViewAssets.headerForegroundUnSelectedColor,
                           backgroundColor: config.onboardingViewAssets.headerBackgroundColor,
                           strokeColor: config.onboardingViewAssets.headerStrokeColor,
                           currentPlanTagColor: config.onboardingViewAssets.currentPlanTagColor,
                           recommendedPlanTagColor: config.onboardingViewAssets.recommendedPlanTagColor)
            
            HStack {
                PlanStorageView(plan: viewModel.plan,
                                primaryTextColor: config.onboardingViewAssets.primaryTextColor,
                                secondaryTextColor: config.onboardingViewAssets.secondaryTextColor)
                Spacer()
                PlanPricingView(plan: viewModel.plan, primaryTextColor: config.onboardingViewAssets.primaryTextColor)
            }
            .padding()
            .padding(.bottom, 5)
        }
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
        viewModel.isSelected ? config.onboardingViewAssets.headerForegroundSelectedColor : config.onboardingViewAssets.headerStrokeColor
    }
}
