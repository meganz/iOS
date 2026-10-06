import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAStoreKit
import UIKit

public struct RevampUpgradePlansDependency: Sendable {
    let fetchUseCase: any RevampUpgradePlansUseCaseProtocol
    let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    let subscriptionsUseCase: any SubscriptionsUseCaseProtocol
    let accountUseCase: any AccountUseCaseProtocol
    let externalPurchaseUseCase: any ExternalPurchaseUseCaseProtocol
    let recommendedUpgradePlanUseCase: any RecommendedUpgradePlanUseCaseProtocol
    let analyticsUseCase: any UpgradePlansAnalyticsUseCaseProtocol
    let viewType: RevampUpgradePlansViewType
    let accountDisplayName: @Sendable (AccountTypeEntity) -> String
    let domainName: String
    let appVersion: String
    /// Opens the external purchase page; `false` when the system could not open it.
    let openURL: @Sendable (URL) async -> Bool
    let notifyPurchaseSucceeded: @Sendable () -> Void
    let purchaseCompleteBehavior: PurchaseCompleteBehavior
    let dismissAction: @MainActor () -> Void
    let termsAndPoliciesPresenter: any TermsAndPoliciesPresenting

    /// Builds the promo-expiry monitor. Defaults to the real factory; tests inject one whose monitor
    /// resolves deterministically instead of sleeping until a deadline.
    let promoExpiryMonitorFactory: any PromoExpiryMonitorFactory

    /// Builds the plan purchaser. Defaults to the real factory; tests and previews inject one
    /// returning a scripted purchaser instead of going through StoreKit.
    let planPurchaserFactory: any PlanPurchaserFactory

    public init(
        fetchUseCase: some RevampUpgradePlansUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        externalPurchaseUseCase: some ExternalPurchaseUseCaseProtocol,
        termsAndPoliciesPresenter: some TermsAndPoliciesPresenting,
        analyticsUseCase: some UpgradePlansAnalyticsUseCaseProtocol,
        viewType: RevampUpgradePlansViewType,
        accountDisplayName: @Sendable @escaping (AccountTypeEntity) -> String,
        domainName: String,
        appVersion: String,
        openURL: @Sendable @escaping (URL) async -> Bool = { @MainActor in await UIApplication.shared.open($0) },
        notifyPurchaseSucceeded: @Sendable @escaping () -> Void = {},
        purchaseCompleteBehavior: PurchaseCompleteBehavior = .dismiss,
        dismissAction: @MainActor @escaping () -> Void = {},
        promoExpiryMonitorFactory: some PromoExpiryMonitorFactory = DefaultPromoExpiryMonitorFactory(),
        planPurchaserFactory: some PlanPurchaserFactory = DefaultPlanPurchaserFactory(),
        recommendedUpgradePlanUseCase: some RecommendedUpgradePlanUseCaseProtocol
            = RecommendedUpgradePlanUseCase(subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase())
    ) {
        self.fetchUseCase = fetchUseCase
        self.purchaseUseCase = purchaseUseCase
        self.subscriptionsUseCase = subscriptionsUseCase
        self.accountUseCase = accountUseCase
        self.externalPurchaseUseCase = externalPurchaseUseCase
        self.viewType = viewType
        self.accountDisplayName = accountDisplayName
        self.domainName = domainName
        self.appVersion = appVersion
        self.openURL = openURL
        self.notifyPurchaseSucceeded = notifyPurchaseSucceeded
        self.purchaseCompleteBehavior = purchaseCompleteBehavior
        self.dismissAction = dismissAction
        self.termsAndPoliciesPresenter = termsAndPoliciesPresenter
        self.promoExpiryMonitorFactory = promoExpiryMonitorFactory
        self.planPurchaserFactory = planPurchaserFactory
        self.analyticsUseCase = analyticsUseCase
        self.recommendedUpgradePlanUseCase = recommendedUpgradePlanUseCase
    }
}
