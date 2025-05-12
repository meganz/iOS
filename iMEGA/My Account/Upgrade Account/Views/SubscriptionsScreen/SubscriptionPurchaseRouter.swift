import Accounts
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Settings
import SwiftUI

final class SubscriptionPurchaseRouter: UpgradeAccountPlanRouting {
    private weak var baseViewController: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let window: UIWindow
    private let accountDetails: AccountDetailsEntity
    private let viewType: UpgradeAccountPlanViewType = .onboarding
    private let onDismiss: () -> Void
    var isFromAds: Bool { false }

    init(
        window: UIWindow,
        currentAccountDetails: AccountDetailsEntity,
        accountUseCase: some AccountUseCaseProtocol,
        onDismiss: @escaping () -> Void
    ) {
        self.window = window
        self.accountDetails = currentAccountDetails
        self.accountUseCase = accountUseCase
        self.onDismiss = onDismiss
    }

    func build() -> UIViewController {
        let viewModel = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: accountUseCase,
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            viewType: viewType,
            router: self,
            appVersion: AppMetaDataFactory(bundle: .main).make().currentAppVersion
        )
        let subscriptionView = SubscriptionPurchaseView(viewModel: viewModel, onDismiss: onDismiss)
        let hostingController = UIHostingController(rootView: subscriptionView)
        baseViewController = hostingController
        return hostingController
    }

    func start() {
        window.rootViewController = build()
    }

    func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            presenter: baseViewController
        ).start()
    }
}
