import MEGADomain
import MEGASwiftUI
import Settings
import SwiftUI

struct UpgradeAccountPlanView: View {
    @StateObject var viewModel: UpgradeAccountPlanViewModel
    @Environment(\.presentationMode) private var presentationMode
    
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
                .foregroundColor(Color(Colors.UpgradeAccount.primaryGrayText.color))
        }
        .padding()
    }
    
    private func planView() -> some View {
        VStack(alignment: .leading) {
            cancelButton
            
            ScrollView {
                LazyVStack(pinnedViews: .sectionFooters) {
                    UpgradeSectionHeaderView(currentPlanName: viewModel.currentPlanName,
                                             selectedTermTab: $viewModel.selectedTermTab)
                    
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
                                }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color(Colors.Background.Regular.primaryElevated.color))
                        }
                    }
                    
                    UpgradeSectionSubscriptionView()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        PlainFooterButtonView(
                            title: Strings.Localizable.UpgradeAccountPlan.Button.Restore.title,
                            didTapButton: $viewModel.isRestoreAccountPlan
                        )
                        
                        PlainFooterButtonView(
                            title: Strings.Localizable.UpgradeAccountPlan.Button.TermsAndPolicies.title,
                            didTapButton: $viewModel.isTermsAndPoliciesPresented
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .onChange(of: viewModel.isDismiss) { newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .alert(isPresented: $viewModel.isAlertPresented) {
            Alert(
                title: Text(viewModel.alertType?.title ?? ""),
                message: Text(viewModel.alertType?.message ?? ""),
                dismissButton: .default(Text(Strings.Localizable.ok))
            )
        }
        .modalView(isPresented: $viewModel.isTermsAndPoliciesPresented, content: {
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
            if #available(iOS 15.0, *) {
                TermsAndPoliciesView(
                    privacyPolicyText: Strings.Localizable.privacyPolicyLabel,
                    cookiePolicyText: Strings.Localizable.General.cookiePolicy,
                    termsOfServicesText: Strings.Localizable.termsOfServicesLabel
                )
                .interactiveDismissDisabled()
            } else {
                TermsAndPoliciesView(
                    privacyPolicyText: Strings.Localizable.privacyPolicyLabel,
                    cookiePolicyText: Strings.Localizable.General.cookiePolicy,
                    termsOfServicesText: Strings.Localizable.termsOfServicesLabel
                )
            }
        }
        
        return NavigationStackView(content: {
            contentView()
                .navigationTitle(Strings.Localizable.Settings.Section.termsAndPolicies)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(Colors.General.Gray.navigationBgColor.color)
                .toolbar {
                    ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                        Button {
                            viewModel.isTermsAndPoliciesPresented = false
                        } label: {
                            Text(Strings.Localizable.close)
                                .foregroundColor(Color(Colors.UpgradeAccount.primaryGrayText.color))
                        }
                    }
                }
        })
    }
}
