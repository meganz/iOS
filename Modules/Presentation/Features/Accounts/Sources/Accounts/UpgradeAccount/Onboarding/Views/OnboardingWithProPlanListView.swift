import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct OnboardingWithProPlanListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: OnboardingUpgradeAccountViewModel
    let accountsConfig: AccountsConfig
    
    @Environment(\.colorScheme) private var colorScheme
    private var backgroundColor: Color {
        TokenColors.Background.page.swiftUI
    }
    
    public var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    OnboardingProPlanHeaderView(
                        lowestPlanPrice: viewModel.lowestProPlan.formattedPrice,
                        accountsConfig: accountsConfig,
                        titleFont: .headline,
                        descriptionFont: .title3,
                        showHeaderImage: false,
                        spacing: 30
                    )
                    .padding(.vertical, 15)
                    
                    OnboardingProPlanContentView(viewModel: viewModel, accountsConfig: accountsConfig)
                    
                    AccountPlanCyclePickerView(selectedCycleTab: $viewModel.selectedCycleTab, subMessageBackgroundColor: accountsConfig.onboardingViewAssets.subMessageBackgroundColor)
                    
                    Section {
                        ForEach(viewModel.filteredPlanList, id: \.self) { plan in
                            AccountPlanView(viewModel: viewModel.createAccountPlanViewModel(plan),
                                            config: accountsConfig)
                            .padding(.bottom, 5)
                            .onAppear {
                                guard plan.type == .proIII else { return }
                                viewModel.trackProIIICardDisplayedEvent()
                            }
                        }
                    }
                    
                    PrimaryActionButtonView(title: Strings.Localizable.continue) {
                        viewModel.purchaseSelectedPlan()
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                    
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
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: 768)
            .clipped()
        }
        .onChange(of: viewModel.shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .disabled(viewModel.isLoading)
        .task {
            await viewModel.setupPlans()
        }
        .throwingTask { try await viewModel.startPurchaseUpdatesMonitoring() }
        .throwingTask { try await viewModel.startRestoreUpdatesMonitoring() }
        .onDisappear {
            viewModel.cancelPurchaseTask()
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
