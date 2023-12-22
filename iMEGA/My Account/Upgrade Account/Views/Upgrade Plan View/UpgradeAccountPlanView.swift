import Accounts
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Settings
import SwiftUI

struct UpgradeAccountPlanView: View {
    @StateObject var viewModel: UpgradeAccountPlanViewModel
    @Environment(\.presentationMode) private var presentationMode
    var invokeDismiss: (() -> Void)?
    
    var body: some View {
        ZStack {
            planView()
            snackBarView()
        }
    }
    
    private var cancelButton: some View {
        Button {
            viewModel.isDismiss = true
        } label: {
            Text(Strings.Localizable.cancel)
                .foregroundColor(Color.upgradeAccountPrimaryGrayText)
        }
        .padding()
    }
    
    private func planView() -> some View {
        VStack(alignment: .leading) {
            cancelButton
            
            ScrollView {
                LazyVStack(pinnedViews: .sectionFooters) {
                    UpgradeSectionHeaderView(currentPlanName: viewModel.currentPlanName,
                                             selectedCycleTab: $viewModel.selectedCycleTab)
                    
                    Section {
                        ForEach(viewModel.filteredPlanList, id: \.self) { plan in
                            AccountPlanView(viewModel: viewModel.createAccountPlanViewModel(plan))
                                .padding(.bottom, 5)
                        }
                        
                        if viewModel.recommendedPlanType == nil {
                            TextWithLinkView(details: viewModel.pricingPageFooterDetails)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        UpgradeSectionFeatureOfProView()
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .disabled(viewModel.isLoading)
        .onChange(of: viewModel.isDismiss) { newValue in
            if newValue {
                dismiss()
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
        .sheet(isPresented: $viewModel.isTermsAndPoliciesPresented, content: {
            termsAndPoliciesView()
        })
    }
    
    private func snackBarView() -> some View {
        VStack {
            Spacer()

            if viewModel.isShowSnackBar {
                SnackBarView(viewModel: viewModel.snackBarViewModel())
            }
        }
    }
    
    private func termsAndPoliciesView() -> some View {
        @ViewBuilder
        func contentView() -> some View {
            TermsAndPoliciesView(
                privacyPolicyText: Strings.Localizable.privacyPolicyLabel,
                cookiePolicyText: Strings.Localizable.General.cookiePolicy,
                termsOfServicesText: Strings.Localizable.termsOfServicesLabel
            )
            .interactiveDismissDisabled()
        }
        
        return NavigationStackView(content: {
            contentView()
                .navigationTitle(Strings.Localizable.Settings.Section.termsAndPolicies)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor.navigationBg)
                .toolbar {
                    ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                        Button {
                            viewModel.isTermsAndPoliciesPresented = false
                        } label: {
                            Text(Strings.Localizable.close)
                                .foregroundColor(Color.upgradeAccountPrimaryGrayText)
                        }
                    }
                }
        })
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
