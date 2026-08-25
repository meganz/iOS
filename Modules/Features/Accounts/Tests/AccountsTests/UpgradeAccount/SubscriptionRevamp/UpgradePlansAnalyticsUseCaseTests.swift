@testable import Accounts
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import MEGATest
import Testing

@Suite("UpgradePlansAnalyticsUseCase")
struct UpgradePlansAnalyticsUseCaseTests {

    // MARK: - Screen view events

    @Test(
        "Reports the screen view against the cached account, split by account type",
        arguments: [
            (AccountTypeEntity.free, true),
            (.lite, false),
            (.proI, false)
        ]
    )
    func trackScreenView_reportsTheAccountType(proLevel: AccountTypeEntity, isFree: Bool) {
        let tracker = MockTracker()
        makeSUT(tracker: tracker, currentAccountDetails: .build(proLevel: proLevel)).trackScreenView()

        assert(tracker, reported: [expectedScreenViewEvent(isFree: isFree)])
    }

    @Test("Reports the screen view against the loaded account in preference to the cached one")
    func trackScreenView_afterThePlansLoad_prefersTheLoadedAccount() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker, currentAccountDetails: .build(proLevel: .free))
        sut.plansDidLoad([], accountDetails: .build(proLevel: .proI))

        sut.trackScreenView()

        assert(tracker, reported: [PaidUserUpgradeAccountPlanScreenEvent()])
    }

    @Test("Reports the screen view as a free user while the account type is unknown")
    func trackScreenView_withoutAnyAccount_reportsTheFreeEvent() {
        let tracker = MockTracker()

        makeSUT(tracker: tracker).trackScreenView()

        assert(tracker, reported: [FreeUserUpgradeAccountPlanScreenEvent()])
    }

    // MARK: - Simple events

    @Test("Reports a dismissal, whichever control was used")
    func trackDismiss() {
        let tracker = MockTracker()
        makeSUT(tracker: tracker).trackDismiss()

        assert(tracker, reported: [MaybeLaterUpgradeAccountButtonPressedEvent()])
    }

    @Test("Reports carrying on with the free plan")
    func trackGetStartedForFree() {
        let tracker = MockTracker()
        makeSUT(tracker: tracker).trackGetStartedForFree()

        assert(tracker, reported: [GetStartedForFreeUpgradePlanButtonPressedEvent()])
    }

    // MARK: - Cycle toggle events

    @Test(
        "Reports the billing period toggle, split by cycle and account type",
        arguments: [
            (SubscriptionCycleEntity.monthly, AccountTypeEntity.free, true),
            (.monthly, .proI, false),
            (.yearly, .free, true),
            (.yearly, .proI, false)
        ]
    )
    func trackCycleToggle_reportsTheCycleAndAccountType(
        cycle: SubscriptionCycleEntity,
        proLevel: AccountTypeEntity,
        isFree: Bool
    ) {
        let tracker = MockTracker()
        makeSUT(tracker: tracker, currentAccountDetails: .build(proLevel: proLevel)).trackCycleToggle(cycle)

        assert(tracker, reported: [expectedCycleEvent(for: cycle, isFree: isFree)])
    }

    @Test("Reports the yearly toggle for a cycle that is neither monthly nor yearly")
    func trackCycleToggle_withNoCycle_reportsTheYearlyEvent() {
        let tracker = MockTracker()
        makeSUT(tracker: tracker, currentAccountDetails: .build(proLevel: .free)).trackCycleToggle(.none)

        assert(tracker, reported: [FreeUserUpgradeAccountPlanYearlyPeriodTogglePressedEvent()])
    }

    @Test("Reports the toggle as a free user while the account type is unknown")
    func trackCycleToggle_withoutAnyAccount_reportsTheFreeEvent() {
        let tracker = MockTracker()

        makeSUT(tracker: tracker).trackCycleToggle(.monthly)

        assert(tracker, reported: [FreeUserUpgradeAccountPlanMonthlyPeriodTogglePressedEvent()])
    }

    // MARK: - Offer expiry events

    @Test(
        "Reports the offer lapsing, split by account type",
        arguments: [
            (AccountTypeEntity.free, true),
            (.proI, false)
        ]
    )
    func trackOfferTimedOut_reportsTheAccountType(proLevel: AccountTypeEntity, isFree: Bool) {
        let tracker = MockTracker()
        makeSUT(tracker: tracker, currentAccountDetails: .build(proLevel: proLevel)).trackOfferTimedOut()

        assert(tracker, reported: [isFree ? FreeUserOfferTimedOutEvent() : PaidUserOfferTimedOutEvent()])
    }

    @Test("Reports the offer expiry as a free user while the account type is unknown")
    func trackOfferTimedOut_withoutAnyAccount_reportsTheFreeEvent() {
        let tracker = MockTracker()

        makeSUT(tracker: tracker).trackOfferTimedOut()

        assert(tracker, reported: [FreeUserOfferTimedOutEvent()])
    }

    // MARK: - Offer eligibility events

    @Test("Reports a paid user being shown an offer on a plan they do not own")
    func trackProUserEligibleForOffers_forAPaidUserWithAnOffer_reports() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(type: .proII, productIdentifier: "pro2.monthly", hasOffer: true)],
            accountDetails: .build(proLevel: .lite, subscriptionCycle: .monthly)
        )

        sut.trackProUserEligibleForOffers()

        assert(tracker, reported: [PaidUserEligibleForOffersEvent()])
    }

    @Test("Reports nothing when the only offer sits on the plan the paid user already owns")
    func trackProUserEligibleForOffers_whenTheOfferIsOnTheCurrentPlan_reportsNothing() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(type: .lite, productIdentifier: "lite.monthly", hasOffer: true)],
            accountDetails: .build(proLevel: .lite, subscriptionCycle: .monthly)
        )

        sut.trackProUserEligibleForOffers()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Reports nothing for a paid user when no plan carries an offer")
    func trackProUserEligibleForOffers_withoutAnyOffer_reportsNothing() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(type: .proII, productIdentifier: "pro2.monthly")],
            accountDetails: .build(proLevel: .lite)
        )

        sut.trackProUserEligibleForOffers()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Reports nothing when the only offer has already lapsed")
    func trackProUserEligibleForOffers_whenTheOfferHasLapsed_reportsNothing() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(
                type: .proII,
                productIdentifier: "pro2.monthly",
                hasOffer: true,
                offerExpiry: Date().addingTimeInterval(-3600)
            )],
            accountDetails: .build(proLevel: .lite)
        )

        sut.trackProUserEligibleForOffers()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Reports eligibility for an offer whose expiry is still ahead")
    func trackProUserEligibleForOffers_whenTheOfferIsStillLive_reports() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(
                type: .proII,
                productIdentifier: "pro2.monthly",
                hasOffer: true,
                offerExpiry: Date().addingTimeInterval(3600)
            )],
            accountDetails: .build(proLevel: .lite)
        )

        sut.trackProUserEligibleForOffers()

        assert(tracker, reported: [PaidUserEligibleForOffersEvent()])
    }

    @Test("Reports nothing for a free user, however many offers are on show")
    func trackProUserEligibleForOffers_forAFreeUser_reportsNothing() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(type: .proII, productIdentifier: "pro2.monthly", hasOffer: true)],
            accountDetails: .build(proLevel: .free)
        )

        sut.trackProUserEligibleForOffers()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Reports nothing when the plans have not loaded yet")
    func trackProUserEligibleForOffers_beforeThePlansLoad_reportsNothing() {
        let tracker = MockTracker()

        makeSUT(tracker: tracker, currentAccountDetails: .build(proLevel: .lite)).trackProUserEligibleForOffers()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    // MARK: - Buy events

    @Test(
        "Reports the plan behind the tapped buy button for a free user",
        arguments: [
            (AccountTypeEntity.lite, "lite.monthly"),
            (.proI, "pro1.monthly"),
            (.proII, "pro2.monthly"),
            (.proIII, "pro3.monthly")
        ]
    )
    func trackBuyPlan_forAFreeUser_reportsThePlanType(type: AccountTypeEntity, productIdentifier: String) {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(type: type, productIdentifier: productIdentifier)],
            accountDetails: .build(proLevel: .free)
        )

        sut.trackBuyPlan(productIdentifier: productIdentifier)

        assert(tracker, reported: [expectedBuyEvent(for: type, isFree: true)])
    }

    @Test(
        "Reports the plan behind the tapped buy button for a paid user",
        arguments: [
            (AccountTypeEntity.lite, "lite.monthly"),
            (.proI, "pro1.monthly"),
            (.proII, "pro2.monthly"),
            (.proIII, "pro3.monthly")
        ]
    )
    func trackBuyPlan_forAPaidUser_reportsThePlanType(type: AccountTypeEntity, productIdentifier: String) {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad(
            [plan(type: type, productIdentifier: productIdentifier)],
            accountDetails: .build(proLevel: .lite)
        )

        sut.trackBuyPlan(productIdentifier: productIdentifier)

        assert(tracker, reported: [expectedBuyEvent(for: type, isFree: false)])
    }

    @Test("Reports nothing when the plans have not loaded yet")
    func trackBuyPlan_beforeThePlansLoad_reportsNothing() {
        let tracker = MockTracker()

        makeSUT(tracker: tracker).trackBuyPlan(productIdentifier: "pro1.monthly")

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Reports nothing for a product identifier that matches no loaded plan")
    func trackBuyPlan_withAnUnknownProductIdentifier_reportsNothing() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad([plan(type: .proI, productIdentifier: "pro1.monthly")], accountDetails: .build())

        sut.trackBuyPlan(productIdentifier: "pro1.yearly")

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("Reports nothing for a plan type that has no buy event")
    func trackBuyPlan_withAnUntrackedPlanType_reportsNothing() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad([plan(type: .proFlexi, productIdentifier: "flexi")], accountDetails: .build())

        sut.trackBuyPlan(productIdentifier: "flexi")

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    // MARK: - Ads events

    @Test("Reports no ads event while the external ads flag is off")
    func trackBuyPlan_withTheAdsFlagOff_reportsNoAdsEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(
            tracker: tracker,
            isFromAds: true,
            isExternalAdsActive: false
        )
        sut.plansDidLoad([plan(type: .proI, productIdentifier: "pro1.monthly")], accountDetails: .build())

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [FreeUserBuyProIEvent()])
    }

    @Test("Reports the ad-free dialog event when the user came from that flow")
    func trackBuyPlan_whenComingFromTheAdFreeDialog_reportsTheAdFreeEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker, isFromAds: true, isExternalAdsActive: true)
        sut.plansDidLoad([plan(type: .proI, productIdentifier: "pro1.monthly")], accountDetails: .build())

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [
            AdFreeDialogUpgradeAccountPlanPageBuyButtonPressedEvent(),
            FreeUserBuyProIEvent()
        ])
    }

    @Test("Reports the ads event for a recent ads dismisser using less than half their quota")
    func trackBuyPlan_whenTheAdsHeuristicMatches_reportsTheAdsEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(
            tracker: tracker,
            isFromAds: false,
            isExternalAdsActive: true,
            lastCloseAdsDate: .now.addingTimeInterval(-.day)
        )
        sut.plansDidLoad(
            [plan(type: .proI, productIdentifier: "pro1.monthly")],
            accountDetails: .build(storageUsed: 10, storageMax: 100)
        )

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [
            AdsUpgradeAccountPlanPageBuyButtonPressedEvent(),
            FreeUserBuyProIEvent()
        ])
    }

    @Test("Reports no ads event when the ads were closed longer ago than two days")
    func trackBuyPlan_whenTheAdsWereClosedTooLongAgo_reportsNoAdsEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(
            tracker: tracker,
            isFromAds: false,
            isExternalAdsActive: true,
            lastCloseAdsDate: .now.addingTimeInterval(-3 * .day)
        )
        sut.plansDidLoad(
            [plan(type: .proI, productIdentifier: "pro1.monthly")],
            accountDetails: .build(storageUsed: 10, storageMax: 100)
        )

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [FreeUserBuyProIEvent()])
    }

    @Test("Reports no ads event when the ads were never closed")
    func trackBuyPlan_whenTheAdsWereNeverClosed_reportsNoAdsEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker, isFromAds: false, isExternalAdsActive: true)
        sut.plansDidLoad(
            [plan(type: .proI, productIdentifier: "pro1.monthly")],
            accountDetails: .build(storageUsed: 10, storageMax: 100)
        )

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [FreeUserBuyProIEvent()])
    }

    @Test("Reports no ads event for a user over half their storage quota")
    func trackBuyPlan_whenTheUserIsOverHalfQuota_reportsNoAdsEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(
            tracker: tracker,
            isFromAds: false,
            isExternalAdsActive: true,
            lastCloseAdsDate: .now.addingTimeInterval(-.day)
        )
        sut.plansDidLoad(
            [plan(type: .proI, productIdentifier: "pro1.monthly")],
            accountDetails: .build(storageUsed: 60, storageMax: 100)
        )

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [FreeUserBuyProIEvent()])
    }

    // MARK: - SUT

    private func makeSUT(
        tracker: MockTracker = MockTracker(),
        isFromAds: Bool = false,
        isExternalAdsActive: Bool = false,
        lastCloseAdsDate: Date? = nil,
        currentAccountDetails: AccountDetailsEntity? = nil
    ) -> UpgradePlansAnalyticsUseCase {
        UpgradePlansAnalyticsUseCase(
            tracker: tracker,
            isFromAds: isFromAds,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsActive]),
            accountUseCase: MockAccountUseCase(currentAccountDetails: currentAccountDetails),
            preferenceUseCase: MockPreferenceUseCase(
                dict: lastCloseAdsDate.map { [PreferenceKeyEntity.lastCloseAdsButtonTappedDate.rawValue: $0] } ?? [:]
            )
        )
    }

    private func plan(
        type: AccountTypeEntity,
        productIdentifier: String,
        hasOffer: Bool = false,
        offerExpiry: Date? = nil
    ) -> PlanEntity {
        PlanEntity(
            productIdentifier: productIdentifier,
            type: type,
            subscriptionCycle: .monthly,
            introductoryOffer: hasOffer ? offer : nil,
            mobileOffer: offerExpiry.map { mobileOffer(expiringAt: $0) }
        )
    }

    private func mobileOffer(expiringAt expiryDate: Date) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "promo",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: expiryDate,
            iosOfferId: nil,
            iosSignature: nil
        )
    }

    private var offer: SubscriptionOfferEntity {
        SubscriptionOfferEntity(
            price: 1,
            period: BillingPeriod(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
    }

    private func expectedScreenViewEvent(isFree: Bool) -> any EventIdentifier {
        isFree ? FreeUserUpgradeAccountPlanScreenEvent() : PaidUserUpgradeAccountPlanScreenEvent()
    }

    private func expectedCycleEvent(for cycle: SubscriptionCycleEntity, isFree: Bool) -> any EventIdentifier {
        switch (cycle, isFree) {
        case (.monthly, true): FreeUserUpgradeAccountPlanMonthlyPeriodTogglePressedEvent()
        case (.monthly, false): PaidUserUpgradeAccountPlanMonthlyPeriodTogglePressedEvent()
        case (_, true): FreeUserUpgradeAccountPlanYearlyPeriodTogglePressedEvent()
        case (_, false): PaidUserUpgradeAccountPlanYearlyPeriodTogglePressedEvent()
        }
    }

    private func expectedBuyEvent(for type: AccountTypeEntity, isFree: Bool) -> any EventIdentifier {
        switch (type, isFree) {
        case (.lite, true): FreeUserBuyProLiteEvent()
        case (.lite, false): PaidUserBuyProLiteEvent()
        case (.proI, true): FreeUserBuyProIEvent()
        case (.proI, false): PaidUserBuyProIEvent()
        case (.proII, true): FreeUserBuyProIIEvent()
        case (.proII, false): PaidUserBuyProIIEvent()
        case (_, true): FreeUserBuyProIIIEvent()
        case (_, false): PaidUserBuyProIIIEvent()
        }
    }

    private func assert(_ tracker: MockTracker, reported events: [any EventIdentifier]) {
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: events
        )
    }
}

private extension TimeInterval {
    static let day: TimeInterval = 60 * 60 * 24
}
