import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

/// The renewal notice and legal links shown at the bottom of the redesigned
/// subscription pages. Shared by the promo and standard pages.
struct SubscriptionLegalFooterView: View {
    private let viewModel: SubscriptionLegalFooterViewModel

    init(dependency: RevampUpgradePlansDependency) {
        viewModel = .init(
            termsAndPoliciesPresenter: dependency.termsAndPoliciesPresenter,
            purchaseUseCase: dependency.purchaseUseCase
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            Button {
                viewModel.restore()
            } label: {
                Text(viewModel.restoreTitle)
                    .font(.footnote.bold())
                    .foregroundStyle(TokenColors.Link.primary.swiftUI)
            }

            Button {
                viewModel.showTermsAndPolicies()
            } label: {
                Text(viewModel.termsAndPoliciesTitle)
                    .font(.footnote.bold())
                    .foregroundStyle(TokenColors.Link.primary.swiftUI)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
