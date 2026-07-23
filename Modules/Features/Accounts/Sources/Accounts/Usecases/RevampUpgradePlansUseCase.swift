import MEGADomain
public protocol RevampUpgradePlansUseCaseProtocol: Sendable {
    /// Available account plans with their introductory and promotional offers merged in.
    func plans() async -> [PlanEntity]
    /// The user's current account details, refreshed when not already cached.
    func currentAccountDetails() async throws -> AccountDetailsEntity
}

public struct RevampUpgradePlansUseCase: RevampUpgradePlansUseCaseProtocol {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let introductoryOfferUseCase: any StoreKitOfferUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol

    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        introductoryOfferUseCase: some StoreKitOfferUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.introductoryOfferUseCase = introductoryOfferUseCase
        self.accountUseCase = accountUseCase
    }

    public func plans() async -> [PlanEntity] {
        var plans = await purchaseUseCase.accountPlanProducts()
        let offers = await introductoryOfferUseCase.fetchOffers(for: plans)
        for index in plans.indices {
            plans[index].introductoryOffer = offers.introductory[plans[index]]
            plans[index].promotionalOffer = offers.promotional[plans[index]]
        }
        return plans
    }

    public func currentAccountDetails() async throws -> AccountDetailsEntity {
        if let details = accountUseCase.currentAccountDetails {
            return details
        }
        return try await accountUseCase.refreshCurrentAccountDetails()
    }
}
