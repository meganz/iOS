import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

enum QuotaDialogUseCaseFactory {
    static func make(
        accountPlanPurchaseUseCase: some AccountPlanPurchaseUseCaseProtocol
    ) -> QuotaDialogUseCase {
        QuotaDialogUseCase(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            accountPlanProductsUseCase: AccountPlanProductsUseCase(
                purchaseUseCase: accountPlanPurchaseUseCase,
                introductoryOfferUseCase: StoreKitOfferUseCase(repository: StoreKitOfferRepository.newRepo)
            ),
            recommendedUpgradePlanUseCase: RecommendedUpgradePlanUseCase(
                subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase()
            )
        )
    }
}
