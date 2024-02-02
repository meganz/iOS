import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI

struct MyAccountHallPlanView: View {
    @ObservedObject var viewModel: MyAccountHallViewModel
    
    var body: some View {
        HStack {
            Image(uiImage: .plan)
                .frame(width: 24, height: 24)
                .padding(.horizontal, 14)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
                    .font(.footnote)
                    .foregroundColor(
                        isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : MEGAAppColor.Account.upgradeAccountPrimaryGrayText.color
                    )
                
                ZStack {
                    ProgressView()
                        .opacity(viewModel.isUpdatingAccountDetails ? 1 : 0)
                    
                    Text(viewModel.currentPlanName)
                        .font(.body)
                        .foregroundColor(
                            isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : MEGAAppColor.Account.upgradeAccountPrimaryGrayText.color
                        )
                        .opacity(viewModel.isUpdatingAccountDetails ? 0 : 1)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.dispatch(.didTapUpgradeButton)
            } label: {
                Text(Strings.Localizable.upgrade)
                    .foregroundColor(
                        isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : MEGAAppColor.View.turquoise.color
                    )
                    .font(.subheadline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : MEGAAppColor.View.turquoise.color,
                                lineWidth: 2
                            )
                    )
            }
            .padding()
        }
        .background(
            isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : MEGAAppColor.Background.backgroundCell.color
        )
    }
}
