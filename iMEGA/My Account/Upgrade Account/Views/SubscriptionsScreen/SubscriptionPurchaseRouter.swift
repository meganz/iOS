import Foundation
import MEGAAppSDKRepo
import MEGADomain
import Settings
import SwiftUI

final class SubscriptionPurchaseRouter: UpgradeAccountPlanRouting {
    private weak var baseViewController: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let presenter: UIViewController
    private let accountDetails: AccountDetailsEntity
    private let viewType: UpgradeAccountPlanViewType = .onboarding
    var isFromAds: Bool { false }

    init(presenter: UIViewController, currentAccountDetails: AccountDetailsEntity, accountUseCase: some AccountUseCaseProtocol) {
        self.presenter = presenter
        self.accountDetails = currentAccountDetails
        self.accountUseCase = accountUseCase
    }

    static func showSubscriptionPurchaseView(presenter: UIViewController) {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        guard let accountDetails = accountUseCase.currentAccountDetails else {
            Task { @MainActor in
                if let accountDetails = try? await accountUseCase.refreshCurrentAccountDetails() {
                    showSubscriptionPurchaseView(
                        presenter: presenter,
                        accountUseCase: accountUseCase,
                        accountDetails: accountDetails
                    )
                }
            }
            return
        }
        showSubscriptionPurchaseView(
            presenter: presenter,
            accountUseCase: accountUseCase,
            accountDetails: accountDetails
        )
    }

    static func showSubscriptionPurchaseView(
        presenter: UIViewController,
        accountUseCase: some AccountUseCaseProtocol,
        accountDetails: AccountDetailsEntity
    ) {
        let router = SubscriptionPurchaseRouter(
            presenter: presenter,
            currentAccountDetails: accountDetails,
            accountUseCase: accountUseCase
        )
        router.start()
    }

    func build() -> UIViewController {
        let viewModel = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: accountUseCase,
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            viewType: viewType,
            router: self
        )
        let subscriptionView = SubscriptionPurchaseView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: subscriptionView)
        hostingController.modalPresentationStyle = .fullScreen
        baseViewController = hostingController
        return hostingController
    }

    func start() {
        presenter.present(build(), animated: true)
    }

    func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            presenter: baseViewController
        ).start()
    }
}
