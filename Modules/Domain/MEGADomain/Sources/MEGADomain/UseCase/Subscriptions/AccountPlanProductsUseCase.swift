public protocol AccountPlanProductsUseCaseProtocol: Sendable {
    /// All purchasable account plans, each with its offers.
    func availablePlans() async -> [PlanEntity]
}

public struct AccountPlanProductsUseCase: AccountPlanProductsUseCaseProtocol {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let introductoryOfferUseCase: any IntroductoryOfferUseCaseProtocol

    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        introductoryOfferUseCase: some IntroductoryOfferUseCaseProtocol
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.introductoryOfferUseCase = introductoryOfferUseCase
    }

    public func availablePlans() async -> [PlanEntity] {
        var plans = await purchaseUseCase.accountPlanProducts()
        let offers = await introductoryOfferUseCase.fetchIntroductoryOffers(for: plans)
        for index in plans.indices {
            plans[index].introductoryOffer = offers[plans[index]]
        }
        return plans
    }
}
