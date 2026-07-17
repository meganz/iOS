import MEGADomain
import MEGAL10n

@MainActor
final class SubscriptionLegalFooterViewModel {

    private let termsAndPoliciesPresenter: any TermsAndPoliciesPresenting
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol

    let restoreTitle = Strings.Localizable.UpgradeAccountPlan.Button.Restore.title
    let termsAndPoliciesTitle = Strings.Localizable.Settings.Section.termsAndPolicies

    init(
        termsAndPoliciesPresenter: some TermsAndPoliciesPresenting,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol
    ) {
        self.termsAndPoliciesPresenter = termsAndPoliciesPresenter
        self.purchaseUseCase = purchaseUseCase
    }

    func restore() {
        purchaseUseCase.restorePurchase()
    }

    func showTermsAndPolicies() {
        termsAndPoliciesPresenter.showTermsAndPolicies()
    }
}
