import MEGADesignToken
import MEGADomain
import MEGAUIComponent
import SwiftUI

struct SubscriptionPromoHeaderView: View {
    private let viewModel: SubscriptionPromoHeaderViewModel

    init(viewModel: SubscriptionPromoHeaderViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MEGABadge(text: viewModel.tag, type: .megaPrimary, size: .small, icon: nil)

            Text(viewModel.title)
                .font(.title.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.vertical, TokenSpacing._4)

            Text(viewModel.subtitle)
                .font(.title2.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.bottom, TokenSpacing._4)

            if let validUntil = viewModel.validUntil {
                Text(validUntil)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .padding(.bottom, TokenSpacing._2)
            }
            
            if let deadline = viewModel.countdownDeadline {
                SubscriptionCountdownTimerView(deadline: deadline)
                    .padding(.top, TokenSpacing._2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
