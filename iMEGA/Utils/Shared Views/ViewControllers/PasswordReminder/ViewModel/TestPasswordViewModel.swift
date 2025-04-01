import MEGAAnalyticsiOS
import MEGAAppPresentation

final class TestPasswordViewModel: NSObject {
    enum TestPasswordAnalyticsEvent {
        case onViewDidLoad, didTapConfirm, didShowWrongPassword, didShowPasswordAccepted, didTapExportRecoveryKey, didTapExportRecoveryKeyCopyOKAlert, didTapProceedToLogout
        
        var eventIdentifier: any EventIdentifier {
            switch self {
            case .onViewDidLoad: TestPasswordScreenEvent()
            case .didTapConfirm: TestPasswordConfirmButtonPressedEvent()
            case .didShowWrongPassword: TestPasswordConfirmWrongPasswordMessageDisplayedEvent()
            case .didShowPasswordAccepted:
                TestPasswordConfirmPasswordAcceptedMessageDisplayedEvent()
            case .didTapExportRecoveryKey: TestPasswordExportRecoveryKeyButtonPressedEvent()
            case .didTapExportRecoveryKeyCopyOKAlert: TestPasswordExportRecoveryKeyOkButtonPressedEvent()
            case .didTapProceedToLogout: TestPasswordProceedToLogoutButtonPressedEvent()
            }
        }
    }
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackEvent(_ event: TestPasswordAnalyticsEvent) {
        tracker.trackAnalyticsEvent(with: event.eventIdentifier)
    }
}
