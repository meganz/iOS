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
    enum PresentationStyle {
        case push, present
    }
    
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let presentationStyle: UpgradePlansRouter.PresentationStyle
    private let accountUseCase: any AccountUseCaseProtocol
    private let viewType: UpgradeAccountPlanViewType
    private let isFromAds: Bool
    private let onDismiss: @MainActor () -> Void
    
    init(
        presenter: UIViewController?,
        presentationStyle: UpgradePlansRouter.PresentationStyle,
        viewType: UpgradeAccountPlanViewType,
        accountUseCase: some AccountUseCaseProtocol,
        isFromAds: Bool = false,
        onDismiss: @escaping @MainActor () -> Void
    ) {
        self.presenter = presenter
        self.presentationStyle = presentationStyle
        self.viewType = viewType
        self.accountUseCase = accountUseCase
        self.isFromAds = isFromAds
        self.onDismiss = onDismiss
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
            accountDisplayName: { $0.toAccountTypeDisplayName() },
            domainName: DIContainer.domainName,
            appVersion: AppMetaDataFactory(bundle: .main).make().currentAppVersion,
            isFromAds: isFromAds,
            notifyPurchaseSucceeded: {
                NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
                NotificationCenter.default.post(name: .dismissOnboardingProPlanDialog, object: nil)
            }
        )
        let view = UpgradePlansContainerView(dependency: dependency, onDismiss: onDismiss)
        let hostingController = UIHostingController(rootView: view)
        hostingController.modalPresentationStyle = .fullScreen
        baseViewController = hostingController
        termsAndPoliciesPresenter.presentingViewController = hostingController
        return hostingController
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
