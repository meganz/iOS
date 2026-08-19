@testable import Accounts
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGATest
import Testing

/// Every dialog event exists as an auto open / triggered pair, and all four resolve through the same
/// launch source. A single wrong branch would silently misattribute eight events, so both halves of
/// each pair are pinned here.
@Suite("PromoLandingDialogAnalytics")
struct PromoLandingDialogAnalyticsTests {

    @Test("The dialog the app opened by itself reports the auto open screen view")
    func trackScreenViewed_appOpen_reportsAutoOpenEvent() {
        assertEvent(launchSource: .appOpen, expected: SubscriptionOfferAutoOpenScreenEvent()) {
            $0.trackScreenViewed()
        }
    }

    @Test("A dialog the user asked for reports the triggered screen view")
    func trackScreenViewed_userTriggered_reportsTriggeredEvent() {
        assertEvent(launchSource: .userTriggered, expected: SubscriptionOfferTriggeredScreenEvent()) {
            $0.trackScreenViewed()
        }
    }

    @Test("Closing the dialog the app opened by itself reports the auto open dismissal")
    func trackDismissButtonPressed_appOpen_reportsAutoOpenEvent() {
        assertEvent(launchSource: .appOpen, expected: SubscriptionOfferAutoOpenDismissButtonPressedEvent()) {
            $0.trackDismissButtonPressed()
        }
    }

    @Test("Closing a dialog the user asked for reports the triggered dismissal")
    func trackDismissButtonPressed_userTriggered_reportsTriggeredEvent() {
        assertEvent(launchSource: .userTriggered, expected: SubscriptionOfferTriggeredDismissButtonPressedEvent()) {
            $0.trackDismissButtonPressed()
        }
    }

    @Test("View all plans from the dialog the app opened by itself reports the auto open press")
    func trackViewAllPlans_appOpen_reportsAutoOpenEvent() {
        assertEvent(launchSource: .appOpen, expected: SubscriptionOfferAutoOpenViewAllPlansButtonPressedEvent()) {
            $0.trackViewAllPlansButtonPressed()
        }
    }

    @Test("View all plans from a dialog the user asked for reports the triggered press")
    func trackViewAllPlans_userTriggered_reportsTriggeredEvent() {
        assertEvent(launchSource: .userTriggered, expected: SubscriptionOfferTriggeredViewAllPlansButtonPressedEvent()) {
            $0.trackViewAllPlansButtonPressed()
        }
    }

    @Test("Buying from the dialog the app opened by itself reports the auto open CTA press")
    func trackBuyPlan_appOpen_reportsAutoOpenEvent() {
        assertEvent(launchSource: .appOpen, expected: SubscriptionOfferAutoOpenCtaButtonPressedEvent()) {
            $0.trackBuyPlan(productIdentifier: "pro1.oneYear")
        }
    }

    @Test("Buying from a dialog the user asked for reports the triggered CTA press")
    func trackBuyPlan_userTriggered_reportsTriggeredEvent() {
        assertEvent(launchSource: .userTriggered, expected: SubscriptionOfferTriggeredCtaButtonPressedEvent()) {
            $0.trackBuyPlan(productIdentifier: "pro1.oneYear")
        }
    }

    // MARK: - Helpers

    private func assertEvent(
        launchSource: PromoLandingDialogAnalytics.LaunchSource,
        expected: some EventIdentifier,
        when track: (PromoLandingDialogAnalytics) -> Void
    ) {
        let tracker = MockTracker()
        let sut = PromoLandingDialogAnalytics(launchSource: launchSource, tracker: tracker)

        track(sut)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [expected]
        )
    }
}
