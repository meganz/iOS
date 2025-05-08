import Accounts
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Settings
import SwiftUI

struct UpgradeAccountPlanView: View {
    @StateObject var viewModel: UpgradeAccountPlanViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.scenePhase) private var scenePhase
    var invokeDismiss: (() -> Void)?
    let accountConfigs: AccountsConfig
    
    var body: some View {
        ZStack {
            planView()
                .snackBar($viewModel.snackBar)
        }
        .onLoad {
            viewModel.onLoad()
        }
    }
    
    private var cancelButton: some View {
        Button {
            viewModel.cancelUpgradeButtonTapped()
        } label: {
            Text(Strings.Localizable.cancel)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
        }
        .padding()
    }
    
    private func planView() -> some View {
        VStack(alignment: .leading) {
            cancelButton
            
            ScrollView {
                LazyVStack(pinnedViews: viewModel.viewType == .upgrade ? .sectionFooters : .init()) {
                    UpgradeSectionHeaderView(currentPlanName: viewModel.currentPlanName,
                                             selectedCycleTab: $viewModel.selectedCycleTab,
                                             subMessageBackgroundColor: TokenColors.Notifications.notificationSuccess.swiftUI)
                    
                    Section {
                        ForEach(viewModel.filteredPlanList, id: \.self) { plan in
                            AccountPlanView(viewModel: viewModel.createAccountPlanViewModel(plan),
                                            config: accountConfigs)
                            .padding(.bottom, 5)
                        }
                        
                        if viewModel.recommendedPlanType == nil {
                            TextWithLinkView(details: viewModel.pricingPageFooterDetails)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        UpgradeSectionFeatureOfProView(showAdFreeContent: viewModel.isExternalAdsActive)
                            .padding(.top, 15)
                        
                    } footer: {
                        if viewModel.isShowBuyButton {
                            VStack {
                                PrimaryActionButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(viewModel.selectedPlanName)) {
                                    viewModel.didTap(.buyPlan)
                                }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundRegularPrimaryElevated)
                        }
                    }
                    
                    UpgradeSectionSubscriptionView()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        PlainFooterButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.Restore.title) {
                            viewModel.didTap(.restorePlan)
                        }
                        
                        PlainFooterButtonView(title: Strings.Localizable.UpgradeAccountPlan.Button.TermsAndPolicies.title) {
                            viewModel.didTap(.termsAndPolicies)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                }
                .padding()
            }
        }
        .frame(maxWidth: 768, alignment: .leading)
        .clipped()
        .disabled(viewModel.isLoading)
        .onChange(of: viewModel.isDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if case .active = newPhase {
                Task { await viewModel.onReturnActive() }
            }
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
