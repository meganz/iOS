import MEGAAnalyticsiOS
import MEGAPresentation

final class HiddenFilesFoldersOnboardingViewModel {
    private let tracker: any AnalyticsTracking
    private let screenEvent: any ScreenViewEventIdentifier
    
    init(tracker: some AnalyticsTracking,
         screenEvent: any ScreenViewEventIdentifier) {
        self.tracker = tracker
        self.screenEvent = screenEvent
    }
    
    func onViewAppear() {
        tracker.trackAnalyticsEvent(with: screenEvent)
    }
    
    func onDismissButtonTapped() {
        tracker.trackAnalyticsEvent(with: HiddenNodeOnboardingCloseButtonPressedEvent())
    }
}
