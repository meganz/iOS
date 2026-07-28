public protocol AccountPlanProductsUseCaseProtocol: Sendable {
    /// All purchasable account plans, each with its offers.
    func availablePlans() async -> [PlanEntity]
}

public struct AccountPlanProductsUseCase: AccountPlanProductsUseCaseProtocol {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let offerUseCase: any StoreKitOfferUseCaseProtocol

    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        offerUseCase: some StoreKitOfferUseCaseProtocol
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.offerUseCase = offerUseCase
    }

    public func availablePlans() async -> [PlanEntity] {
        var plans = await purchaseUseCase.accountPlanProducts()
        let offers = await offerUseCase.fetchOffers(for: plans)
        for index in plans.indices {
            plans[index].introductoryOffer = offers.introductory[plans[index]]
            plans[index].promotionalOffer = offers.promotional[plans[index]]
        }
        return plans
    }
}
