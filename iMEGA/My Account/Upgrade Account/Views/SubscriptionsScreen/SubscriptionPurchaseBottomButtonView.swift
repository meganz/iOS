import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct SubscriptionPurchaseBottomButtonView: View {
    @ObservedObject var viewModel: UpgradeAccountPlanViewModel

    var body: some View {
        if viewModel.buyButtons.isNotEmpty {
            MEGABottomAnchoredButtons(buttons: viewModel.buyButtons)
        }
    }
}
