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

    // MARK: - Simple events

    @Test("Reports the screen view")
    func trackScreenView() {
        let tracker = MockTracker()
        makeSUT(tracker: tracker).trackScreenView()

        assert(tracker, reported: [UpgradeAccountPlanScreenEvent()])
    }

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

    // MARK: - Buy events

    @Test(
        "Reports the plan behind the tapped buy button",
        arguments: [
            (AccountTypeEntity.lite, "lite.monthly"),
            (.proI, "pro1.monthly"),
            (.proII, "pro2.monthly"),
            (.proIII, "pro3.monthly")
        ]
    )
    func trackBuyPlan_reportsThePlanType(type: AccountTypeEntity, productIdentifier: String) {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.plansDidLoad([plan(type: type, productIdentifier: productIdentifier)], accountDetails: .build())

        sut.trackBuyPlan(productIdentifier: productIdentifier)

        assert(tracker, reported: [expectedBuyEvent(for: type)])
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

        assert(tracker, reported: [BuyProIEvent()])
    }

    @Test("Reports the ad-free dialog event when the user came from that flow")
    func trackBuyPlan_whenComingFromTheAdFreeDialog_reportsTheAdFreeEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker, isFromAds: true, isExternalAdsActive: true)
        sut.plansDidLoad([plan(type: .proI, productIdentifier: "pro1.monthly")], accountDetails: .build())

        sut.trackBuyPlan(productIdentifier: "pro1.monthly")

        assert(tracker, reported: [
            AdFreeDialogUpgradeAccountPlanPageBuyButtonPressedEvent(),
            BuyProIEvent()
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
            BuyProIEvent()
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

        assert(tracker, reported: [BuyProIEvent()])
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

        assert(tracker, reported: [BuyProIEvent()])
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

        assert(tracker, reported: [BuyProIEvent()])
    }

    // MARK: - SUT

    private func makeSUT(
        tracker: MockTracker = MockTracker(),
        isFromAds: Bool = false,
        isExternalAdsActive: Bool = false,
        lastCloseAdsDate: Date? = nil
    ) -> UpgradePlansAnalyticsUseCase {
        UpgradePlansAnalyticsUseCase(
            tracker: tracker,
            isFromAds: isFromAds,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsActive]),
            preferenceUseCase: MockPreferenceUseCase(
                dict: lastCloseAdsDate.map { [PreferenceKeyEntity.lastCloseAdsButtonTappedDate.rawValue: $0] } ?? [:]
            )
        )
    }

    private func plan(type: AccountTypeEntity, productIdentifier: String) -> PlanEntity {
        PlanEntity(productIdentifier: productIdentifier, type: type, subscriptionCycle: .monthly)
    }

    private func expectedBuyEvent(for type: AccountTypeEntity) -> any EventIdentifier {
        switch type {
        case .lite: BuyProLiteEvent()
        case .proI: BuyProIEvent()
        case .proII: BuyProIIEvent()
        default: BuyProIIIEvent()
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
