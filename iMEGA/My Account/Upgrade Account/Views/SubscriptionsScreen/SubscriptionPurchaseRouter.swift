import Foundation
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

    static func showSubscriptionPurchaseView(in window: UIWindow, onDismiss: @escaping () -> Void) {
        Task {
            let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
            let accountDetails = try await loadAccountDetails(using: accountUseCase)
            await MEGAPurchase.sharedInstance().requestPricingAsync()

            showSubscriptionPurchaseView(
                window: window,
                accountUseCase: accountUseCase,
                accountDetails: accountDetails,
                onDismiss: onDismiss
            )
        }
    }

    private static func loadAccountDetails(
        using useCase: AccountUseCase<AccountRepository>
    ) async throws -> AccountDetailsEntity {
        if let details = useCase.currentAccountDetails {
            return details
        }
        return try await useCase.refreshCurrentAccountDetails()
    }

    @MainActor
    static func showSubscriptionPurchaseView(
        window: UIWindow,
        accountUseCase: some AccountUseCaseProtocol,
        accountDetails: AccountDetailsEntity,
        onDismiss: @escaping () -> Void
    ) {
        let router = SubscriptionPurchaseRouter(
            window: window,
            currentAccountDetails: accountDetails,
            accountUseCase: accountUseCase,
            onDismiss: onDismiss
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
