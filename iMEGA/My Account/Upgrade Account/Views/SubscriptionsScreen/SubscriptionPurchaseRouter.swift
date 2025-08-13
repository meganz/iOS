import Accounts
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Settings
import SwiftUI

final class SubscriptionPurchaseRouter: UpgradeAccountPlanRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountDetails: AccountDetailsEntity
    private let viewType: UpgradeAccountPlanViewType
    private let onDismiss: (() -> Void)?
    let isFromAds: Bool

    init(
        presenter: UIViewController?,
        currentAccountDetails: AccountDetailsEntity,
        viewType: UpgradeAccountPlanViewType,
        accountUseCase: some AccountUseCaseProtocol,
        isFromAds: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.presenter = presenter
        self.accountDetails = currentAccountDetails
        self.viewType = viewType
        self.accountUseCase = accountUseCase
        self.isFromAds = isFromAds
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
        let subscriptionView = SubscriptionPurchaseView(
            viewModel: viewModel,
            onDismiss: onDismiss ?? dismiss)
        let hostingController = UIHostingController(rootView: subscriptionView)
        hostingController.modalPresentationStyle = .fullScreen
        baseViewController = hostingController
        return hostingController
    }

    func start() {
        presenter?.present(build(), animated: true)
    }

    func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            appDomainUseCase: DIContainer.appDomainUseCase,
            presenter: baseViewController
        ).start()
    }
    
    private func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
}
