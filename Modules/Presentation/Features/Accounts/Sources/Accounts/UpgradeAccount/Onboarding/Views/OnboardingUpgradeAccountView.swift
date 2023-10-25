import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct OnboardingUpgradeAccountView: View {
    var viewModel: OnboardingUpgradeAccountViewModel
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                OnboardingProPlanHeaderView(
                    lowestPlanPrice: viewModel.lowestProPlan.formattedPrice
                )
                .padding(.top, 30)
                
                OnboardingProPlanContentView(viewModel: viewModel)
                
                Spacer()
                
                VStack(spacing: 15) {
                    PrimaryActionButtonView(title: Strings.Localizable.Onboarding.UpgradeAccount.Button.viewProPlans) {}
                    
                    SecondaryActionButtonView(title: Strings.Localizable.skipButton) {}
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: 390)
        .taskForiOS14 {
            viewModel.setUpLowestProPlan()
        }
    }
}

private struct OnboardingProPlanHeaderView: View {
    var lowestPlanPrice: String
    
    @Environment(\.colorScheme) var colorScheme
    private var subTitleColor: Color {
        colorScheme == .dark ? Color(red: 0.81, green: 0.81, blue: 0.81) : Color(red: 0.32, green: 0.32, blue: 0.32)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Image("onboardingHeader")
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
                .font(.title3)
                .bold()
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.subTitle(lowestPlanPrice))
                .foregroundColor(subTitleColor)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
    }
}
