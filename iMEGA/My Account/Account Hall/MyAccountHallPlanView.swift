import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct MyAccountHallPlanView: View {
    @ObservedObject var viewModel: MyAccountHallViewModel
    
    private var separatorColor: Color {
        TokenColors.Border.strong.swiftUI
    }
    
    var body: some View {
        HStack {
            Image(uiImage: .plan)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 24, height: 24)
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 18))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                
                ZStack {
                    ProgressView()
                        .opacity(viewModel.isUpdatingAccountDetails ? 1 : 0)
                    
                    Text(viewModel.currentPlanName)
                        .font(.body)
                        .foregroundStyle( TokenColors.Text.primary.swiftUI)
                        .opacity(viewModel.isUpdatingAccountDetails ? 0 : 1)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.dispatch(.didTapUpgradeButton)
            } label: {
                Text(Strings.Localizable.upgrade)
                    .foregroundStyle(TokenColors.Text.inverseAccent.swiftUI)
                    .font(.subheadline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                    .background(TokenColors.Button.primary.swiftUI)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
            }
            .padding()
        }
        .background()
        .separatorView(offset: 55, color: separatorColor)
    }
}
