import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct SubscriptionPurchaseBottomButtonView: View {
    @ObservedObject var viewModel: UpgradeAccountPlanViewModel

    var body: some View {
        if viewModel.isShowBuyButton {
            VStack(spacing: 0) {
                Divider()
                PrimaryActionButtonView(
                    title: Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(viewModel.selectedPlanName),
                    font: .callout.bold()
                ) {
                    viewModel.didTap(.buyPlan)
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical)
                .maxWidthForWideScreen()
            }
            .background(TokenColors.Background.page.swiftUI)
        }
    }
}
