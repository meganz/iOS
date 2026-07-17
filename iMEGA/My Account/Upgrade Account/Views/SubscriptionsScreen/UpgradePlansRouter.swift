import Accounts
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import Settings
import SwiftUI

@MainActor
final class UpgradePlansRouter {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountDetails: AccountDetailsEntity
    private let viewType: UpgradeAccountPlanViewType
    private let isFromAds: Bool

    init(
        presenter: UIViewController?,
        currentAccountDetails: AccountDetailsEntity,
        viewType: UpgradeAccountPlanViewType,
        accountUseCase: some AccountUseCaseProtocol,
        isFromAds: Bool = false,
    ) {
        self.presenter = presenter
        self.accountDetails = currentAccountDetails
        self.viewType = viewType
        self.accountUseCase = accountUseCase
        self.isFromAds = isFromAds
    }

    func build() -> UIViewController {
        let purchaseUseCase = AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo)
        let fetchUseCase = RevampUpgradePlansUseCase(
            purchaseUseCase: purchaseUseCase,
            introductoryOfferUseCase: IntroductoryOfferUseCase(repository: IntroductoryOfferRepository.newRepo),
            accountUseCase: accountUseCase
        )

        let termsAndPoliciesPresenter = TermsAndPoliciesPresenter(accountUseCase: accountUseCase)
        let dependency = RevampUpgradePlansDependency(
            fetchUseCase: fetchUseCase,
            purchaseUseCase: purchaseUseCase,
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            accountUseCase: accountUseCase,
            externalPurchaseUseCase: DIContainer.externalPurchaseUseCase,
            remoteFeatureFlagUseCase: DIContainer.remoteFeatureFlagUseCase,
            termsAndPoliciesPresenter: termsAndPoliciesPresenter,
            tracker: DIContainer.tracker,
            viewType: revampViewType,
            domainName: DIContainer.domainName,
            appVersion: AppMetaDataFactory(bundle: .main).make().currentAppVersion,
            isFromAds: isFromAds,
            notifyPurchaseSucceeded: {
                NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
                NotificationCenter.default.post(name: .dismissOnboardingProPlanDialog, object: nil)
            }
        )
        let viewModel = UpgradePlansContainerViewModel(dependency: dependency)
        let view = UpgradePlansContainerView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        baseViewController = hostingController
        termsAndPoliciesPresenter.presentingViewController = hostingController
        return hostingController
    }

    func start() {
        presenter?.present(build(), animated: true)
    }

    private var revampViewType: RevampUpgradePlansViewType {
        switch viewType {
        case .onboarding(let isFreeAccountFirstLogin):
            .onboarding(isFreeAccountFirstLogin: isFreeAccountFirstLogin)
        case .upgrade:
            .upgrade
        }
    }
}

@MainActor
private class TermsAndPoliciesPresenter: TermsAndPoliciesPresenting {
    private let accountUseCase: any AccountUseCaseProtocol
    weak var presentingViewController: UIViewController?

    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
    }

    func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            domainNameHandler: { DIContainer.domainName },
            presenter: presentingViewController
        ).start()
    }
}
