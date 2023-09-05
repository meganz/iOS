import MEGAL10n
import SwiftUI

struct MyAccountHallPlanView: View {
    @ObservedObject var viewModel: AccountHallViewModel
    
    var body: some View {
        HStack {
            Image(uiImage: Asset.Images.MyAccount.plan.image)
                .frame(width: 24, height: 24)
                .padding(.horizontal, 14)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
                    .font(.footnote)
                    .foregroundColor(Color(Colors.UpgradeAccount.primaryGrayText.color))
                
                ZStack {
                    ProgressView()
                        .opacity(viewModel.isUpdatingAccountDetails ? 1 : 0)
                    
                    Text(viewModel.currentPlanName)
                        .font(.body)
                        .foregroundColor(Color(Colors.UpgradeAccount.primaryText.color))
                        .opacity(viewModel.isUpdatingAccountDetails ? 0 : 1)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.dispatch(.didTapUpgradeButton)
            } label: {
                Text(Strings.Localizable.upgrade)
                    .foregroundColor(Color(Colors.Views.turquoise.color))
                    .font(.subheadline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(Colors.Views.turquoise.color), lineWidth: 2)
                    )
            }
            .padding()
        }
        .background(Color(Colors.General.Background.cellColor.color))
    }
}
