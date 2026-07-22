import Accounts
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import Settings
import SwiftUI

protocol UpgradeAccountPlanRouting: Routing {
    func showTermsAndPolicies()
    var isFromAds: Bool { get }
}

final class SubscriptionPurchaseRouter: UpgradeAccountPlanRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountDetails: AccountDetailsEntity
    private let presentationStyle: UpgradePlansRouter.PresentationStyle
    private let viewType: UpgradeAccountPlanViewType
    private let onDismiss: (@MainActor () -> Void)?
    let isFromAds: Bool

    init(
        presenter: UIViewController?,
        currentAccountDetails: AccountDetailsEntity,
        presentationStyle: UpgradePlansRouter.PresentationStyle = .present,
        viewType: UpgradeAccountPlanViewType,
        accountUseCase: some AccountUseCaseProtocol,
        isFromAds: Bool = false,
        onDismiss: (@MainActor () -> Void)? = nil
    ) {
        self.presenter = presenter
        self.accountDetails = currentAccountDetails
        self.presentationStyle = presentationStyle
        self.viewType = viewType
        self.accountUseCase = accountUseCase
        self.isFromAds = isFromAds
        self.onDismiss = onDismiss
    }

    func build() -> UIViewController {
        if isRevampUpgradePlansEnabled {
            let controller = UpgradePlansRouter(
                presenter: presenter,
                presentationStyle: presentationStyle,
                viewType: viewType,
                accountUseCase: accountUseCase,
                isFromAds: isFromAds,
                onDismiss: onDismiss ?? dismiss
            ).build()
            baseViewController = controller
            return controller
        }

        let viewModel = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: accountUseCase,
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            introductoryOfferUseCase: IntroductoryOfferUseCase(
                repository: IntroductoryOfferRepository.newRepo
            ),
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
        let viewController = build()
        switch presentationStyle {
        case .push:
            if let navigationController = presenter as? UINavigationController {
                navigationController.pushViewController(viewController, animated: true)
            } else {
                presenter?.present(viewController, animated: true)
            }
        case .present:
            presenter?.present(viewController, animated: true)
        }
    }

    func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            domainNameHandler: { DIContainer.domainName },
            presenter: baseViewController
        ).start()
    }
    
    private func dismiss() {
        switch presentationStyle {
        case .push:
            if let navigationController = baseViewController?.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                baseViewController?.dismiss(animated: true)
            }
        case .present:
            baseViewController?.dismiss(animated: true)
        }
    }

    private var isRevampUpgradePlansEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .upgradeAccountPlanRevamp)
    }
}
