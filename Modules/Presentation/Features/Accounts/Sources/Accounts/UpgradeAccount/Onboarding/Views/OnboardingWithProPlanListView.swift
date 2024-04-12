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
            Color("background_regular_primaryElevated").edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10, pinnedViews: .sectionFooters) {
                    OnboardingProPlanHeaderView(
                        lowestPlanPrice: viewModel.lowestProPlan.formattedPrice,
                        primaryGrayTextColor: accountsConfig.onboardingViewAssets.primaryGrayTextColor
                    )
                    .padding(.vertical, 15)
                    
                    OnboardingProPlanContentView(viewModel: viewModel, accountsConfig: accountsConfig)
                    
                    AccountPlanCyclePickerView(selectedCycleTab: $viewModel.selectedCycleTab, subMessageBackgroundColor: accountsConfig.onboardingViewAssets.subMessageBackgroundColor)
                    
                    Section {
                        ForEach(viewModel.filteredPlanList, id: \.self) { plan in
                            AccountPlanView(viewModel: viewModel.createAccountPlanViewModel(plan),
                                            config: accountsConfig)
                            .padding(.bottom, 5)
                        }
                    } footer: {
                        PrimaryActionButtonView(title: Strings.Localizable.continue) {
                            viewModel.purchaseSelectedPlan()
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(Color("background_regular_primaryElevated"))
                    }
                    
                    UpgradeSectionSubscriptionView()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        PlainFooterButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.Restore.title) {
                            viewModel.restorePurchase()
                        }
                        
                        PlainFooterButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.TermsAndPolicies.title) {
                            viewModel.showTermsAndPolicies()
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
        .alert(isPresented: $viewModel.isAlertPresented) {
            if let alertType = viewModel.alertType,
               let secondaryButtonTitle = alertType.secondaryButtonTitle {
                return Alert(
                    title: Text(alertType.title),
                    message: Text(alertType.message),
                    primaryButton: .default(Text(alertType.primaryButtonTitle), action: alertType.primaryButtonAction),
                    secondaryButton: .cancel(Text(secondaryButtonTitle))
                )
            } else {
                return Alert(
                    title: Text(viewModel.alertType?.title ?? ""),
                    message: Text(viewModel.alertType?.message ?? ""),
                    dismissButton: .default(Text(viewModel.alertType?.primaryButtonTitle ?? ""))
                )
            }
        }
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

private struct OnboardingProPlanHeaderView: View {
    var lowestPlanPrice: String
    var primaryGrayTextColor: Color
    
    var body: some View {
        VStack(spacing: 30) {
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
                .font(.headline)
                .bold()
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.subTitle(lowestPlanPrice))
                .foregroundColor(primaryGrayTextColor)
                .font(.title3)
                .multilineTextAlignment(.center)
        }
    }
}
