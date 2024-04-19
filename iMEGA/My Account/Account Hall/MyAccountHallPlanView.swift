import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct MyAccountHallPlanView: View {
    @ObservedObject var viewModel: MyAccountHallViewModel
    
    @Environment(\.colorScheme) var colorScheme
    private var separatorColor: Color {
        guard isDesignTokenEnabled else {
            return colorScheme == .dark ? Color(red: 38/255, green: 38/255, blue: 38/255, opacity: 1.0) : Color(red: 240/255, green: 240/255, blue: 240/255, opacity: 1.0)
        }
        return TokenColors.Border.strong.swiftUI
    }
    
    var body: some View {
        HStack {
            Image(uiImage: .plan)
                .renderingMode(isDesignTokenEnabled ? .template : .original)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Icon.primary.swiftUI : Color.primary)
                .frame(width: 24, height: 24)
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 18))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
                    .font(.footnote)
                    .foregroundStyle(
                        isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : MEGAAppColor.Account.upgradeAccountPrimaryGrayText.color
                    )
                
                ZStack {
                    ProgressView()
                        .opacity(viewModel.isUpdatingAccountDetails ? 1 : 0)
                    
                    Text(viewModel.currentPlanName)
                        .font(.body)
                        .foregroundStyle(
                            isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label)
                        )
                        .opacity(viewModel.isUpdatingAccountDetails ? 0 : 1)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.dispatch(.didTapUpgradeButton)
            } label: {
                Text(Strings.Localizable.upgrade)
                    .foregroundStyle(
                        isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : MEGAAppColor.View.turquoise.color
                    )
                    .font(.subheadline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                    .background(
                        isDesignTokenEnabled ? TokenColors.Button.primary.swiftUI : Color.clear
                    )
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .overlay( // Overlay should be removed when design token is permanently applied as it won't be needed.
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isDesignTokenEnabled ? Color.clear : MEGAAppColor.View.turquoise.color,
                                lineWidth: 2
                            )
                    )
            }
            .padding()
        }
        .background(
            isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : MEGAAppColor.Background.backgroundCell.color
        )
        .separatorView(offset: 55, color: separatorColor)
    }
}
