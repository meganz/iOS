import MEGAAnalyticsiOS
import MEGAAppPresentation

enum InitialLaunchAction: ActionType {
    case didTapSetUpMEGAButton
    case didTapSkipSetUpButton
}

final class InitialLaunchViewModel: ViewModelType {
    var invokeCommand: ((Command) -> Void)?
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: any AnalyticsTracking) {
        self.tracker = tracker
    }
    
    // MARK: - Dispatch actions
    func dispatch(_ action: InitialLaunchAction) {
        switch action {
        case .didTapSetUpMEGAButton: trackSetUpMEGAButtonTappedEvent()
        case .didTapSkipSetUpButton: trackSkipSetUpButtonTappedEvent()
        }
    }
    
    private func trackSetUpMEGAButtonTappedEvent() {
        tracker.trackAnalyticsEvent(with: InitialLaunchSetUpButtonPressedEvent())
    }
    
    private func trackSkipSetUpButtonTappedEvent() {
        tracker.trackAnalyticsEvent(with: InitialLaunchSkipSetUpButtonPressedEvent())
    }
}
