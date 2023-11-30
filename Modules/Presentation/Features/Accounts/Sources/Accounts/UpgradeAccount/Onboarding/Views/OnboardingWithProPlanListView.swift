import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct OnboardingWithProPlanListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: OnboardingUpgradeAccountViewModel
    let accountsConfig: AccountsConfig
    
    public var body: some View {
        ZStack {
            Color("primaryElevated").edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10, pinnedViews: .sectionFooters) {
                    OnboardingProPlanHeaderView(
                        lowestPlanPrice: viewModel.lowestProPlan.formattedPrice
                    )
                    .padding(.vertical, 15)
                    
                    OnboardingProPlanContentView(viewModel: viewModel, accountsConfig: accountsConfig)
                    
                    AccountPlanCyclePickerView(selectedCycleTab: $viewModel.selectedCycleTab)
                    
                    Section {
                        ForEach(viewModel.filteredPlanList, id: \.self) { plan in
                            AccountPlanView(viewModel: viewModel.createAccountPlanViewModel(plan))
                                .padding(.bottom, 5)
                        }
                    } footer: {
                        PrimaryActionButtonView(title: Strings.Localizable.continue) {
                            dismiss()
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(Color("primaryElevated"))
                    }
                    
                    UpgradeSectionSubscriptionView()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        PlainFooterButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.Restore.title) {
                        }
                        
                        PlainFooterButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.TermsAndPolicies.title) {
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                }
                .frame(maxWidth: 390)
                .padding(.horizontal, 16)
            }
            .clipped()
        }
        .onChange(of: viewModel.shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .task {
            await viewModel.setupPlans()
        }
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

private struct OnboardingProPlanHeaderView: View {
    var lowestPlanPrice: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
                .font(.headline)
                .bold()
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.subTitle(lowestPlanPrice))
                .foregroundColor(Color("primaryGrayText"))
                .font(.title3)
                .multilineTextAlignment(.center)
        }
    }
}
