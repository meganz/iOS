import MEGAAnalyticsiOS
import MEGAPresentation

struct InviteContactTracking {
    
    static var inviteContactTracker: InviteContactTracking {
        .init(tracker: DIContainer.tracker)
    }
    
    var tracker: any AnalyticsTracking
    
    func trackAddFromContactsTapped() {
        tracker.trackAnalyticsEvent(with: InviteToMEGAAddFromContactsEvent())
    }
    func trackEnterEmailAddressTapped() {
        tracker.trackAnalyticsEvent(with: InviteToMEGAEnterEmailAddressEvent())
    }

    func trackScanCodeTapped() {
        tracker.trackAnalyticsEvent(with: InviteToMEGAScanCodeEvent())
    }

    func trackShareInviteTapped() {
        tracker.trackAnalyticsEvent(with: InviteToMEGAShareInviteEvent())
    }
    
    func trackInviteScreen() {
        tracker.trackAnalyticsEvent(with: InviteContactScreenEvent())
    }
}
