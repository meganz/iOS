import Foundation
import MEGADomain

public protocol PlanPurchaserFactory: Sendable {
    @MainActor func makePurchaser(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) -> any PlanPurchasing

    @MainActor func makeExternalPurchaser(
        linkProvider: some ExternalPurchaseLinkProviding,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        domainName: String,
        appVersion: String,
        canOpenURL: @escaping @Sendable (URL) async -> Bool,
        openURL: @escaping @Sendable (URL) async -> Void
    ) -> any ExternalPlanPurchasing
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
            eligibilityChecker: PlanPurchaseEligibilityChecker(
                subscriptionsUseCase: subscriptionsUseCase,
                accountUseCase: accountUseCase
            ),
            tracker: DIContainer.tracker
        )
    }

    @MainActor
    public func makeExternalPurchaser(
        linkProvider: some ExternalPurchaseLinkProviding,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        domainName: String,
        appVersion: String,
        canOpenURL: @escaping @Sendable (URL) async -> Bool,
        openURL: @escaping @Sendable (URL) async -> Void
    ) -> any ExternalPlanPurchasing {
        ExternalPlanPurchaser(
            linkProvider: linkProvider,
            purchaseUseCase: purchaseUseCase,
            accountUseCase: accountUseCase,
            eligibilityChecker: PlanPurchaseEligibilityChecker(accountUseCase: accountUseCase),
            domainName: domainName,
            appVersion: appVersion,
            canOpenURL: canOpenURL,
            openURL: openURL
        )
    }
}
