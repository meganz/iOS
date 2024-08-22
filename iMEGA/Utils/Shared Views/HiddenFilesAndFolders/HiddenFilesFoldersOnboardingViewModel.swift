import MEGAAnalyticsiOS
import MEGAPresentation

final class HiddenFilesFoldersOnboardingViewModel {
    let showPrimaryButtonOnly: Bool
    let showNavigationBar: Bool
    
    private let tracker: any AnalyticsTracking
    private let screenEvent: (any ScreenViewEventIdentifier)?
    private let dismissEvent: (any ButtonPressedEventIdentifier)?
    
    init(showPrimaryButtonOnly: Bool,
         showNavigationBar: Bool = true,
         tracker: some AnalyticsTracking = DIContainer.tracker,
         screenEvent: (any ScreenViewEventIdentifier)? = nil,
         dismissEvent: (any ButtonPressedEventIdentifier)? = nil
        ) {
        self.showPrimaryButtonOnly = showPrimaryButtonOnly
        self.showNavigationBar = showNavigationBar
        self.tracker = tracker
        self.screenEvent = screenEvent
        self.dismissEvent = dismissEvent
    }
    
    func onViewAppear() {
        guard let screenEvent else { return }
        tracker.trackAnalyticsEvent(with: screenEvent)
    }
    
    func onDismissButtonTapped() {
        guard let dismissEvent else { return }
        tracker.trackAnalyticsEvent(with: dismissEvent)
    }
}
