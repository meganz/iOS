@testable import Accounts
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

    @Test("The only offer on the table leaves nothing to point at, so the upgrade page is not offered")
    func viewAllPlans_singleOffer_isHidden() {
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

    // MARK: - Helpers

    private func makeSUT(
        hasMultipleOffers: Bool = false,
        dismissAction: @escaping @MainActor () -> Void = {},
        onPurchased: @escaping @MainActor () -> Void = {},
        viewAllPlansAction: @escaping @MainActor () -> Void = {},
        tracker: MockTracker = MockTracker()
    ) -> PromoLandingDialogContentViewModel {
        PromoLandingDialogContentViewModel(
            dependency: PromoLandingDialogContentView.Dependency(
                fetchResult: fetchResult(hasMultipleOffers: hasMultipleOffers),
                launchSource: .userTriggered,
                planPurchaser: MockPlanPurchasing(),
                dismissAction: dismissAction,
                onPurchased: onPurchased,
                viewAllPlansAction: viewAllPlansAction,
                tracker: tracker
            )
        )
    }

    private func fetchResult(hasMultipleOffers: Bool) -> PromotedPlanFetchResult {
        let offer = MobileOfferEntity(
            id: "black-friday-2026",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: 2026
        )
        return PromotedPlanFetchResult(
            promotedPlan: PromotedPlanEntity(
                plan: PlanEntity(
                    type: .proI,
                    appStorePrice: PlanPriceEntity(price: 100, formattedPrice: "", currency: "USD"),
                    mobileOffer: offer
                ),
                offer: offer
            ),
            hasMultipleOffers: hasMultipleOffers
        )
    }
}
