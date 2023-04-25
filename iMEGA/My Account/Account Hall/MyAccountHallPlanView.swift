import SwiftUI

struct MyAccountHallPlanView: View {
    var viewModel: MyAccountHallPlanViewModel
    
    var body: some View {
        HStack {
            Image(uiImage: Asset.Images.MyAccount.plan.image)
                .frame(width: 24, height: 24)
                .padding(.horizontal, 14)
            
            VStack(alignment: .leading) {
                Text(Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
                    .font(.footnote)
                    .foregroundColor(Color(Colors.UpgradeAccount.primaryGrayText.color))
                
                Text(viewModel.currentPlan)
                    .font(.body)
                    .foregroundColor(Color(Colors.UpgradeAccount.primaryText.color))
            }
            
            Spacer()
            
            Button {
                viewModel.tappedUpgradeButton()
            } label: {
                Text(Strings.Localizable.upgrade)
                    .foregroundColor(Color(Colors.UpgradeAccount.buttonTint.color))
                    .font(.subheadline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .overlay (
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(Colors.UpgradeAccount.buttonTint.color), lineWidth: 2)
                    )
            }
            .padding()
        }
        .background(Color(Colors.General.Background.cellColor.color))
    }
}
