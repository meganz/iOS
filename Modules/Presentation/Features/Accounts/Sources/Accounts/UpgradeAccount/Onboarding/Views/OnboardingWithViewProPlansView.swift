import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct OnboardingWithViewProPlansView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: OnboardingUpgradeAccountViewModel
    public var invokeDismiss: (() -> Void)?
    let accountsConfig: AccountsConfig
    
    public var body: some View {
        ZStack {
            Color("background_regular_primaryElevated").edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    OnboardingProPlanHeaderView(
                        lowestPlanPrice: viewModel.lowestProPlan.formattedPrice,
                        accountsConfig: accountsConfig
                    )
                    .padding(.top, 30)
                    
                    OnboardingProPlanContentView(viewModel: viewModel, accountsConfig: accountsConfig)
                    
                    VStack(spacing: 15) {
                        PrimaryActionButtonView(title: Strings.Localizable.Onboarding.UpgradeAccount.Button.viewProPlans) {
                            viewModel.showProPlanView()
                        }
                        
                        SecondaryActionButtonView(title: Strings.Localizable.skipButton) {
                            dismiss()
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 2, bottom: 20, trailing: 2))
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: 390)
            }
        }
        .onChange(of: viewModel.shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .task {
            await viewModel.setUpLowestProPlan()
        }
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

private struct OnboardingProPlanHeaderView: View {
    let lowestPlanPrice: String
    let accountsConfig: AccountsConfig
    
    var body: some View {
        VStack(spacing: 10) {
            Image(uiImage: accountsConfig.onboardingViewAssets.onboardingHeaderImage)
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
                .font(.title3)
                .bold()
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.subTitle(lowestPlanPrice))
                .foregroundColor(accountsConfig.onboardingViewAssets.primaryGrayTextColor)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
    }
}
