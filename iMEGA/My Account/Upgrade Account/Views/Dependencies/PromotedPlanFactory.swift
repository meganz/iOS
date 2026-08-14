import Accounts
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import UIKit

// Consolidate reusable components for related features of Promoted Landing Dialog.
enum PromotedPlanFactory {
    static func makeProvider() -> @Sendable () async throws -> PlanEntity? {
        let promotedPlanUseCase = makeUseCase()

        return {
            guard await DIContainer.remoteFeatureFlagUseCase
                .isFeatureFlagEnabledAfterReady(for: .iosUpgradeAccountPlanRevamp) else { return nil }
            return try await promotedPlanUseCase.fetchPromotedPlan(checksForExpiry: true)?.plan
        }
    }

    static func makeUseCase(
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol = AccountPlanPurchaseUseCase(
            repository: AccountPlanPurchaseRepository.newRepo
        )
    ) -> PromotedPlanUseCase {
        PromotedPlanUseCase(
            pricingRequester: PricingRequester.shared,
            fetchUseCase: RevampUpgradePlansUseCase(
                productsUseCase: AccountPlanProductsUseCase(
                    purchaseUseCase: purchaseUseCase,
                    offerUseCase: StoreKitOfferUseCase(repository: StoreKitOfferRepository.newRepo)
                ),
                accountUseCase: accountUseCase
            )
        )
    }
}

extension PromoLandingDialogRouter {
    static func makeDefault(presenter: UIViewController?) -> PromoLandingDialogRouter {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let purchaseUseCase = AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo)

        return PromoLandingDialogRouter(
            presenter: presenter,
            promotedPlanUseCase: PromotedPlanFactory.makeUseCase(
                accountUseCase: accountUseCase,
                purchaseUseCase: purchaseUseCase
            ),
            planPurchaser: DefaultPlanPurchaserFactory().makePurchaser(
                purchaseUseCase: purchaseUseCase,
                subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
                accountUseCase: accountUseCase
            )
        )
    }
}
