import MEGAAnalyticsiOS
import MEGAPresentation

final class HiddenFilesFoldersOnboardingViewModel {
    private let tracker: any AnalyticsTracking
    private let screenEvent: any ScreenViewEventIdentifier
    private let dismissEvent: any ButtonPressedEventIdentifier
    
    init(tracker: some AnalyticsTracking,
         screenEvent: any ScreenViewEventIdentifier,
         dismissEvent: any ButtonPressedEventIdentifier
        ) {
        self.tracker = tracker
        self.screenEvent = screenEvent
        self.dismissEvent = dismissEvent
    }
    
    func onViewAppear() {
        tracker.trackAnalyticsEvent(with: screenEvent)
    }
    
    func onDismissButtonTapped() {
        tracker.trackAnalyticsEvent(with: dismissEvent)
    }
}
