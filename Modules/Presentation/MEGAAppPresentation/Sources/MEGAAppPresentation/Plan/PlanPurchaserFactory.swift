import MEGADomain

public protocol PlanPurchaserFactory: Sendable {
    @MainActor func makePurchaser(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) -> any PlanPurchasing
}

public struct DefaultPlanPurchaserFactory: PlanPurchaserFactory {
    public init() {}

    @MainActor
    public func makePurchaser(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) -> any PlanPurchasing {
        PlanPurchaser(
            purchaseUseCase: purchaseUseCase,
            subscriptionsUseCase: subscriptionsUseCase,
            accountUseCase: accountUseCase,
            tracker: DIContainer.tracker
        )
    }
}
