@testable import Accounts
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGATest
import Testing

@Suite("PromoLandingDialogContentViewModel")
@MainActor
struct PromoLandingDialogContentViewModelTests {

    @Test("Appearing on screen reports the screen view")
    func onAppear_reportsTheScreenView() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)

        sut.onAppear()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SubscriptionOfferTriggeredScreenEvent()]
        )
    }

    @Test("The close button reports the dismissal and closes the dialog")
    func closeButtonTapped_reportsTheDismissalAndDismisses() {
        var dismissed = false
        let tracker = MockTracker()
        let sut = makeSUT(dismissAction: { dismissed = true }, tracker: tracker)

        sut.closeButtonTapped()

        #expect(dismissed)
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SubscriptionOfferTriggeredDismissButtonPressedEvent()]
        )
    }

    /// The dialog closes itself once a purchase lands. The user dismissed nothing, so reporting a
    /// dismissal there would count a dismiss press on every purchase.
    @Test("Closing after a purchase reports no dismissal")
    func purchaseCompleted_dismissesWithoutReportingADismissal() {
        var dismissed = false
        var purchased = false
        let tracker = MockTracker()
        let sut = makeSUT(
            dismissAction: { dismissed = true },
            onPurchased: { purchased = true },
            tracker: tracker
        )

        sut.purchaseCompleted()

        #expect(purchased)
        #expect(dismissed)
        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    @Test("While the promotion is live, a lone offer leaves nothing to point at, so the upgrade page is not offered")
    func viewAllPlans_singleLiveOffer_isHidden() {
        let sut = makeSUT(hasMultipleOffers: false)

        guard case .hidden = sut.viewAllPlans else {
            Issue.record("Expected the button to be hidden for a single offer")
            return
        }
    }

    @Test("View all plans reports the press before opening the upgrade page")
    func viewAllPlansAction_reportsThePressBeforeRunning() {
        var trackedEventCountWhenActionRan: Int?
        let tracker = MockTracker()
        let sut = makeSUT(
            hasMultipleOffers: true,
            viewAllPlansAction: { trackedEventCountWhenActionRan = tracker.trackedEventIdentifiers.count },
            tracker: tracker
        )

        guard case .shown(let action) = sut.viewAllPlans else {
            Issue.record("Expected the button to be shown while other plans are on offer")
            return
        }

        action()

        #expect(trackedEventCountWhenActionRan == 1)
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SubscriptionOfferTriggeredViewAllPlansButtonPressedEvent()]
        )
    }

    // MARK: - Offer expiry

    @Test("A promotion that lapsed before the dialog appeared starts out expired")
    func isOfferExpired_whenPromotionAlreadyLapsed_isTrueBeforeMonitoring() {
        let sut = makeSUT(offerExpiry: .now, timer: MockPromoExpiryTimer(hasAlreadyExpired: true))

        #expect(sut.isOfferExpired)
    }

    @Test("A live promotion starts out unexpired")
    func isOfferExpired_whenPromotionIsLive_isFalse() {
        let sut = makeSUT(offerExpiry: .now, timer: MockPromoExpiryTimer(hasAlreadyExpired: false))

        #expect(!sut.isOfferExpired)
    }

    /// The buy button goes away when the promotion lapses, so the upgrade page has to be offered even
    /// when nothing else was on the table - otherwise the dialog leaves the user nowhere to go.
    @Test("The promotion lapsing offers the upgrade page, even with no other offer on the table")
    func monitorOfferExpiry_whenPromotionLapses_expiresAndOffersAllPlans() async {
        let sut = makeSUT(hasMultipleOffers: false, offerExpiry: .now, timer: MockPromoExpiryTimer(expires: true))

        await sut.monitorOfferExpiry()

        #expect(sut.isOfferExpired)
        guard case .shown = sut.viewAllPlans else {
            Issue.record("Expected the upgrade page to be offered once the promotion lapsed")
            return
        }
    }

    @Test("A cancelled wait leaves the buy button in place")
    func monitorOfferExpiry_whenWaitIsCancelled_staysUnexpired() async {
        let sut = makeSUT(offerExpiry: .now, timer: MockPromoExpiryTimer(expires: false))

        await sut.monitorOfferExpiry()

        #expect(!sut.isOfferExpired)
    }

    @Test("A plan carrying no expiring promotional offer has nothing to wait for")
    func monitorOfferExpiry_whenOfferNeverExpires_doesNotWait() async {
        let timer = MockPromoExpiryTimer()
        let sut = makeSUT(offerExpiry: nil, timer: timer)

        await sut.monitorOfferExpiry()

        #expect(timer.waitUntilExpiredCallCount == 0)
        #expect(!sut.isOfferExpired)
    }

    // MARK: - Helpers

    private func makeSUT(
        hasMultipleOffers: Bool = false,
        offerExpiry: Date? = nil,
        timer: MockPromoExpiryTimer = MockPromoExpiryTimer(),
        dismissAction: @escaping @MainActor () -> Void = {},
        onPurchased: @escaping @MainActor () -> Void = {},
        viewAllPlansAction: @escaping @MainActor () -> Void = {},
        tracker: MockTracker = MockTracker()
    ) -> PromoLandingDialogContentViewModel {
        PromoLandingDialogContentViewModel(
            dependency: PromoLandingDialogContentView.Dependency(
                fetchResult: fetchResult(hasMultipleOffers: hasMultipleOffers, offerExpiry: offerExpiry),
                launchSource: .userTriggered,
                planPurchaser: MockPlanPurchasing(),
                dismissAction: dismissAction,
                onPurchased: onPurchased,
                viewAllPlansAction: viewAllPlansAction,
                makePromoExpiryTimer: { _ in timer },
                tracker: tracker
            )
        )
    }

    /// A non-nil `offerExpiry` produces a plan whose promotional offer is both valid and expiring,
    /// which is what makes the dialog build a timer in the first place.
    private func fetchResult(hasMultipleOffers: Bool, offerExpiry: Date? = nil) -> PromotedPlanFetchResult {
        let offer = MobileOfferEntity(
            id: "black-friday-2026",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: nil,
            expiryDate: offerExpiry,
            iosOfferId: nil,
            iosSignature: offerExpiry == nil ? nil : .stub,
            campaignId: 2026
        )
        return PromotedPlanFetchResult(
            promotedPlan: PromotedPlanEntity(
                plan: PlanEntity(
                    type: .proI,
                    appStorePrice: PlanPriceEntity(price: 100, formattedPrice: "", currency: "USD"),
                    mobileOffer: offer,
                    promotionalOffer: offerExpiry == nil ? nil : .stub
                ),
                offer: offer
            ),
            hasMultipleOffers: hasMultipleOffers
        )
    }
}

@MainActor
private final class MockPromoExpiryTimer: PromoExpiryTiming {
    let hasAlreadyExpired: Bool
    private let expires: Bool
    private(set) var waitUntilExpiredCallCount = 0

    init(hasAlreadyExpired: Bool = false, expires: Bool = true) {
        self.hasAlreadyExpired = hasAlreadyExpired
        self.expires = expires
    }

    func waitUntilExpired() async -> Bool {
        waitUntilExpiredCallCount += 1
        return expires
    }
}
