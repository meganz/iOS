import MEGAAnalyticsiOS
import MEGAAppPresentation

/// The analytics the promo landing dialog reports, resolved against the entry point that opened it:
/// the app open auto show reports the auto open half of each event pair, every user triggered entry
/// point reports the triggered half.
public struct PromoLandingDialogAnalytics: Sendable {
    /// How the dialog reached the screen, which decides the half of each event pair it reports
    public enum LaunchSource: Sendable {
        case appOpen
        case userTriggered
    }

    private let launchSource: LaunchSource
    private let tracker: any AnalyticsTracking

    init(launchSource: LaunchSource, tracker: some AnalyticsTracking) {
        self.launchSource = launchSource
        self.tracker = tracker
    }

    func trackScreenViewed() {
        track(
            appOpen: SubscriptionOfferAutoOpenScreenEvent(),
            userTriggered: SubscriptionOfferTriggeredScreenEvent()
        )
    }

    func trackDismissButtonPressed() {
        track(
            appOpen: SubscriptionOfferAutoOpenDismissButtonPressedEvent(),
            userTriggered: SubscriptionOfferTriggeredDismissButtonPressedEvent()
        )
    }

    func trackViewAllPlansButtonPressed() {
        track(
            appOpen: SubscriptionOfferAutoOpenViewAllPlansButtonPressedEvent(),
            userTriggered: SubscriptionOfferTriggeredViewAllPlansButtonPressedEvent()
        )
    }

    private func track(
        appOpen: @autoclosure () -> any EventIdentifier,
        userTriggered: @autoclosure () -> any EventIdentifier
    ) {
        switch launchSource {
        case .appOpen:
            tracker.trackAnalyticsEvent(with: appOpen())
        case .userTriggered:
            tracker.trackAnalyticsEvent(with: userTriggered())
        }
    }
}

// MARK: - PlanPurchaseTracking

extension PromoLandingDialogAnalytics: PlanPurchaseTracking {
    public func trackBuyPlan(productIdentifier: String) {
        track(
            appOpen: SubscriptionOfferAutoOpenCtaButtonPressedEvent(),
            userTriggered: SubscriptionOfferTriggeredCtaButtonPressedEvent()
        )
    }
}
