import MEGADomain
public protocol RevampUpgradePlansUseCaseProtocol: Sendable {
    /// Available account plans with their introductory offers merged in.
    func plans() async -> [PlanEntity]
    /// The user's current account details, refreshed when not already cached.
    func currentAccountDetails() async throws -> AccountDetailsEntity
}

public struct RevampUpgradePlansUseCase: RevampUpgradePlansUseCaseProtocol {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let introductoryOfferUseCase: any IntroductoryOfferUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol

    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        introductoryOfferUseCase: some IntroductoryOfferUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.introductoryOfferUseCase = introductoryOfferUseCase
        self.accountUseCase = accountUseCase
    }

    public func plans() async -> [PlanEntity] {
        var plans = await purchaseUseCase.accountPlanProducts()
        let offers = await introductoryOfferUseCase.fetchIntroductoryOffers(for: plans)
        for index in plans.indices {
            plans[index].introductoryOffer = offers[plans[index]]
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
