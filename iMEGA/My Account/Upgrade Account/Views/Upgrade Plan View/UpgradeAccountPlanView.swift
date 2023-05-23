import MEGADomain
import MEGASwiftUI
import SwiftUI

struct UpgradeAccountPlanView: View {
    @StateObject var viewModel: UpgradeAccountPlanViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    private var cancelButton: some View {
        Button {
            viewModel.isDismiss = true
        } label: {
            Text(Strings.Localizable.cancel)
                .foregroundColor(Color(Colors.UpgradeAccount.primaryGrayText.color))
        }
        .padding()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            cancelButton
            
            ScrollView {
                LazyVStack(pinnedViews: .sectionFooters) {
                    UpgradeSectionHeaderView(currentPlanName: viewModel.currentPlanName,
                                             selectedTermIndex: $viewModel.selectedTermIndex)
                    
                    Section {
                        UpgradeSectionFeatureOfProView()
                    } footer: {
                        if viewModel.isShowBuyButton {
                            VStack {
                                PrimaryActionButtonView(title: UpgradeStrings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(viewModel.selectedPlanName)) {
                                }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color(Colors.Background.Regular.primaryElevated.color))
                        }
                    }
                    
                    UpgradeSectionSubscriptionView()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        PlainFooterButtonView(title: UpgradeStrings.Localizable.UpgradeAccountPlan.Button.Restore.title) {}
                        
                        PlainFooterButtonView(title: UpgradeStrings.Localizable.UpgradeAccountPlan.Button.TermsAndPolicies.title) {}
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
    }
}
