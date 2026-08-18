import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGAPreference
import MEGASwift

/// Every analytics event the redesigned Upgrade screen reports.
public protocol UpgradePlansAnalyticsUseCaseProtocol: PlanPurchaseTracking {
    /// Hands over the plans a report needs to name the plan behind a tapped buy button, and the
    /// account the ads eligibility rules are gated on.
    func plansDidLoad(_ plans: [PlanEntity], accountDetails: AccountDetailsEntity)
    func trackScreenView()
    func trackDismiss()
    func trackGetStartedForFree()
    func trackCycleToggle(_ cycle: SubscriptionCycleEntity)
}

public final class UpgradePlansAnalyticsUseCase: @unchecked Sendable {
    /// The loaded plans and the account they were loaded against, held as one value so a report
    /// never sees the plans of one load beside the account details of another.
    private struct LoadedPlans: Sendable {
        let plans: [PlanEntity]
        let accountDetails: AccountDetailsEntity
    }

    private let tracker: any AnalyticsTracking
    private let isFromAds: Bool
    private let isExternalAdsActive: Bool

    @Atomic private var loaded: LoadedPlans?

    @PreferenceWrapper(key: PreferenceKeyEntity.lastCloseAdsButtonTappedDate, defaultValue: nil)
    private var lastCloseAdsDate: Date?

    public init(
        tracker: some AnalyticsTracking,
        isFromAds: Bool,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default
    ) {
        self.tracker = tracker
        self.isFromAds = isFromAds
        isExternalAdsActive = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
        $lastCloseAdsDate.useCase = preferenceUseCase
    }

    public func plansDidLoad(_ plans: [PlanEntity], accountDetails: AccountDetailsEntity) {
        $loaded.mutate { $0 = LoadedPlans(plans: plans, accountDetails: accountDetails) }
    }

    // MARK: - Events

    public func trackScreenView() {
        tracker.trackAnalyticsEvent(with: UpgradeAccountPlanScreenEvent())
    }

    public func trackDismiss() {
        tracker.trackAnalyticsEvent(with: MaybeLaterUpgradeAccountButtonPressedEvent())
    }

    public func trackGetStartedForFree() {
        tracker.trackAnalyticsEvent(with: GetStartedForFreeUpgradePlanButtonPressedEvent())
    }

    public func trackCycleToggle(_ cycle: SubscriptionCycleEntity) {
        if cycle == .monthly {
            tracker.trackAnalyticsEvent(with: UpgradeAccountPlanMonthlyPeriodTogglePressedEvent())
        } else {
            tracker.trackAnalyticsEvent(with: UpgradeAccountPlanYearlyPeriodTogglePressedEvent())
        }
    }
}

// MARK: - UpgradePlansAnalyticsUseCaseProtocol

extension UpgradePlansAnalyticsUseCase: UpgradePlansAnalyticsUseCaseProtocol {
    /// Reports a buy button tap, from either the in-app or the website route.
    public func trackBuyPlan(productIdentifier: String) {
        if isExternalAdsActive {
            trackBuyPlanForAds(accountDetails: loaded?.accountDetails)
        }

        guard let plan = loaded?.plans.first(where: { $0.productIdentifier == productIdentifier }) else { return }

        switch plan.type {
        case .proI:
            tracker.trackAnalyticsEvent(with: BuyProIEvent())
        case .proII:
            tracker.trackAnalyticsEvent(with: BuyProIIEvent())
        case .proIII:
            tracker.trackAnalyticsEvent(with: BuyProIIIEvent())
        case .lite:
            tracker.trackAnalyticsEvent(with: BuyProLiteEvent())
        default:
            break
        }
    }

    // MARK: - Ads

    private func trackBuyPlanForAds(accountDetails: AccountDetailsEntity?) {
        // User buys a plan coming from the Ad-free flow
        guard !isFromAds else {
            tracker.trackAnalyticsEvent(with: AdFreeDialogUpgradeAccountPlanPageBuyButtonPressedEvent())
            return
        }

        // User buys a plan without going through the Ad-free flow but matches these requirements:
        // - The user is using less that 50% of their storage quota
        // - The timestamp on close ads button tap is within the last 2 days
        guard let accountDetails,
              isAdsClosedWithinLastTwoDays(),
              hasUsedLessThanHalfQuota(used: accountDetails.storageUsed, quota: accountDetails.storageMax) else {
            return
        }

        tracker.trackAnalyticsEvent(with: AdsUpgradeAccountPlanPageBuyButtonPressedEvent())
    }

    private func isAdsClosedWithinLastTwoDays() -> Bool {
        guard let lastCloseAdsDate,
              let daysOfDistance = Date().dayDistance(toPastDate: lastCloseAdsDate, on: Calendar.current) else {
            return false
        }
        return daysOfDistance <= 2
    }

    private func hasUsedLessThanHalfQuota(used: Int64, quota: Int64) -> Bool {
        used < (quota / 2)
    }
}
