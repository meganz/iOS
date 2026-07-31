import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

enum QuotaDialogUseCaseFactory {
    static func make(
        accountPlanPurchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        pricingRequester: some PricingRequesting
    ) -> QuotaDialogUseCase {
        QuotaDialogUseCase(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            accountPlanProductsUseCase: AccountPlanProductsUseCase(
                purchaseUseCase: accountPlanPurchaseUseCase,
                offerUseCase: StoreKitOfferUseCase(repository: StoreKitOfferRepository.newRepo)
            ),
            recommendedUpgradePlanUseCase: RecommendedUpgradePlanUseCase(
                subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase()
            ),
            pricingRequester: pricingRequester
        )
    }
}
