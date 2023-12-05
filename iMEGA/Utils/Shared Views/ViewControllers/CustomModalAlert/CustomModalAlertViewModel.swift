import MEGAAnalyticsiOS
import MEGAPresentation

final class CustomModalAlertViewModel: NSObject {
    struct CustomModalAlertViewAnalyticEvents {
        let dialogDisplayedEventIdentifier: (any DialogDisplayedEventIdentifier)?
        let fistButtonPressedEventIdentifier: (any ButtonPressedEventIdentifier)?
    }
    
    private let tracker: any AnalyticsTracking
    private let analyticsEvents: CustomModalAlertViewAnalyticEvents?
    
    init(tracker: some AnalyticsTracking,
         analyticsEvents: CustomModalAlertViewAnalyticEvents?) {
        self.tracker = tracker
        self.analyticsEvents = analyticsEvents
    }
    
    @objc func onViewDidLoad() {
        guard let dialogDisplayedEventIdentifier = analyticsEvents?.dialogDisplayedEventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: dialogDisplayedEventIdentifier)
    }
    
    @objc func firstButtonTapped() {
        guard let fistButtonPressedEventIdentifier = analyticsEvents?.fistButtonPressedEventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: fistButtonPressedEventIdentifier)
    }
}
