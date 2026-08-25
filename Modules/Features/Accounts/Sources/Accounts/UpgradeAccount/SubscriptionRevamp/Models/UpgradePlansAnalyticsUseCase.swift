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
    /// Reports the featured promotional offer lapsing while the user was on the screen.
    func trackOfferTimedOut()
    /// Reports a Pro user being shown at least one live promotional offer. Call once the plans are in.
    func trackProUserEligibleForOffers()
}

public final class UpgradePlansAnalyticsUseCase: @unchecked Sendable {
    /// The loaded plans and the account they were loaded against, held as one value so a report
    /// never sees the plans of one load beside the account details of another.
    private struct LoadedPlans: Sendable {
        let plans: [PlanEntity]
        let accountDetails: AccountDetailsEntity
    }

    private let tracker: any AnalyticsTracking
    private let accountUseCase: any AccountUseCaseProtocol
    private let isFromAds: Bool
    private let isExternalAdsActive: Bool

    @Atomic private var loaded: LoadedPlans?

    @PreferenceWrapper(key: PreferenceKeyEntity.lastCloseAdsButtonTappedDate, defaultValue: nil)
    private var lastCloseAdsDate: Date?

    public init(
        tracker: some AnalyticsTracking,
        isFromAds: Bool,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default
    ) {
        self.tracker = tracker
        self.accountUseCase = accountUseCase
        self.isFromAds = isFromAds
        isExternalAdsActive = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
        $lastCloseAdsDate.useCase = preferenceUseCase
    }

    public func plansDidLoad(_ plans: [PlanEntity], accountDetails: AccountDetailsEntity) {
        $loaded.mutate { $0 = LoadedPlans(plans: plans, accountDetails: accountDetails) }
    }

    // MARK: - Events

    public func trackScreenView() {
        let event: any EventIdentifier = isFreeAccount
            ? FreeUserUpgradeAccountPlanScreenEvent()
            : PaidUserUpgradeAccountPlanScreenEvent()
        tracker.trackAnalyticsEvent(with: event)
    }

    public func trackDismiss() {
        tracker.trackAnalyticsEvent(with: MaybeLaterUpgradeAccountButtonPressedEvent())
    }

    public func trackGetStartedForFree() {
        tracker.trackAnalyticsEvent(with: GetStartedForFreeUpgradePlanButtonPressedEvent())
    }

    public func trackCycleToggle(_ cycle: SubscriptionCycleEntity) {
        let event: any EventIdentifier = switch (cycle, isFreeAccount) {
        case (.monthly, true): FreeUserUpgradeAccountPlanMonthlyPeriodTogglePressedEvent()
        case (.monthly, false): PaidUserUpgradeAccountPlanMonthlyPeriodTogglePressedEvent()
        case (_, true): FreeUserUpgradeAccountPlanYearlyPeriodTogglePressedEvent()
        case (_, false): PaidUserUpgradeAccountPlanYearlyPeriodTogglePressedEvent()
        }
        tracker.trackAnalyticsEvent(with: event)
    }

    public func trackOfferTimedOut() {
        let event: any EventIdentifier = isFreeAccount
            ? FreeUserOfferTimedOutEvent()
            : PaidUserOfferTimedOutEvent()
        tracker.trackAnalyticsEvent(with: event)
    }

    public func trackProUserEligibleForOffers() {
        guard let loaded, !loaded.accountDetails.isFree, hasVisibleOffer(in: loaded) else { return }

        tracker.trackAnalyticsEvent(with: PaidUserEligibleForOffersEvent())
    }

    private func hasVisibleOffer(in loaded: LoadedPlans) -> Bool {
        loaded.plans.contains {
            $0.applicableOffer != nil
                && !$0.isCurrentPlan(for: loaded.accountDetails)
                && $0.mobileOffer?.hasExpired != true
        }
    }

    /// We use `loaded?.accountDetails` as a primary source of truth,
    /// However when `loaded?.accountDetails` is not available (e.g: calling trackScreenView() when data is still loading),
    /// we fallback to using the cache from `accountUseCase.currentAccountDetails`, and finally to
    /// `true`, so an unattributable report still lands as a free user rather than being dropped.
    private var isFreeAccount: Bool {
        loaded?.accountDetails.isFree ?? accountUseCase.currentAccountDetails?.isFree ?? true
    }
}

// MARK: - UpgradePlansAnalyticsUseCaseProtocol

extension UpgradePlansAnalyticsUseCase: UpgradePlansAnalyticsUseCaseProtocol {
    /// Reports a buy button tap, from either the in-app or the website route.
    public func trackBuyPlan(productIdentifier: String) {
        if isExternalAdsActive {
            trackBuyPlanForAds(accountDetails: loaded?.accountDetails)
        }

        guard let loaded,
              let plan = loaded.plans.first(where: { $0.productIdentifier == productIdentifier }),
              let event = buyPlanEvent(for: plan.type, isFree: loaded.accountDetails.isFree) else { return }

        tracker.trackAnalyticsEvent(with: event)
    }

    private func buyPlanEvent(for type: AccountTypeEntity, isFree: Bool) -> (any EventIdentifier)? {
        switch type {
        case .proI: isFree ? FreeUserBuyProIEvent() : PaidUserBuyProIEvent()
        case .proII: isFree ? FreeUserBuyProIIEvent() : PaidUserBuyProIIEvent()
        case .proIII: isFree ? FreeUserBuyProIIIEvent() : PaidUserBuyProIIIEvent()
        case .lite: isFree ? FreeUserBuyProLiteEvent() : PaidUserBuyProLiteEvent()
        default: nil
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
