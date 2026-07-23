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
    let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    let tracker: any AnalyticsTracking
    let viewType: RevampUpgradePlansViewType
    let accountDisplayName: @Sendable (AccountTypeEntity) -> String
    let domainName: String
    let appVersion: String
    let isFromAds: Bool
    let canOpenURL: @Sendable (URL) async -> Bool
    let openURL: @Sendable (URL) async -> Void
    let notifyPurchaseSucceeded: @Sendable () -> Void
    let termsAndPoliciesPresenter: any TermsAndPoliciesPresenting

    public init(
        fetchUseCase: some RevampUpgradePlansUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        externalPurchaseUseCase: some ExternalPurchaseUseCaseProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        termsAndPoliciesPresenter: some TermsAndPoliciesPresenting,
        tracker: some AnalyticsTracking,
        viewType: RevampUpgradePlansViewType,
        accountDisplayName: @Sendable @escaping (AccountTypeEntity) -> String,
        domainName: String,
        appVersion: String,
        isFromAds: Bool,
        canOpenURL: @Sendable @escaping (URL) async -> Bool = { UIApplication.shared.canOpenURL($0) },
        openURL: @Sendable @escaping (URL) async -> Void = { url in
            await MainActor.run { UIApplication.shared.open(url) }
        },
        notifyPurchaseSucceeded: @Sendable @escaping () -> Void = {},
    ) {
        self.fetchUseCase = fetchUseCase
        self.purchaseUseCase = purchaseUseCase
        self.subscriptionsUseCase = subscriptionsUseCase
        self.accountUseCase = accountUseCase
        self.externalPurchaseUseCase = externalPurchaseUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.tracker = tracker
        self.viewType = viewType
        self.accountDisplayName = accountDisplayName
        self.domainName = domainName
        self.appVersion = appVersion
        self.isFromAds = isFromAds
        self.canOpenURL = canOpenURL
        self.openURL = openURL
        self.notifyPurchaseSucceeded = notifyPurchaseSucceeded
        self.termsAndPoliciesPresenter = termsAndPoliciesPresenter
    }
}
