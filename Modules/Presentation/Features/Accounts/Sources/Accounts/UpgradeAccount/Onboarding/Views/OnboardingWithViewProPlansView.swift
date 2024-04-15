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
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        }
        return TokenColors.Background.page.swiftUI
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
    @Environment(\.colorScheme) private var colorScheme
    let lowestPlanPrice: String
    let accountsConfig: AccountsConfig
    
    var body: some View {
        VStack(spacing: 10) {
            Image(uiImage: accountsConfig.onboardingViewAssets.onboardingHeaderImage)
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
                .font(.title3)
                .bold()
                .foregroundStyle(
                    isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(.label)
                )
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.subTitle(lowestPlanPrice))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isDesignTokenEnabled ?
                    TokenColors.Text.secondary.swiftUI :
                        colorScheme == .dark ? Color(red: 181/255, green: 181/255, blue: 181/255) : Color(red: 132/255, green: 132/255, blue: 132/255)
                )
        }
    }
}
