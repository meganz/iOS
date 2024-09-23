import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct OnboardingWithViewProPlansView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: OnboardingUpgradeAccountViewModel
    public var invokeDismiss: (() -> Void)?
    let accountsConfig: AccountsConfig
    
    @Environment(\.colorScheme) private var colorScheme
    private var backgroundColor: Color {
        TokenColors.Background.page.swiftUI
    }
    
    public var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
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
                    .padding(EdgeInsets(top: 10, leading: 2, bottom: 20, trailing: 2))
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: 768)
            }
            .clipped()
        }
        .onChange(of: viewModel.shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .task {
            await viewModel.setUpLowestProPlan()
        }
        .onAppear {
            viewModel.setUpSubscription()
        }
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
