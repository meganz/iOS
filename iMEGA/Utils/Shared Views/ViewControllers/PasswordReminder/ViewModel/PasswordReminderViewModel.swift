import MEGAAnalyticsiOS
import MEGAPresentation

final class PasswordReminderViewModel: NSObject {
    enum PasswordReminderAnalyticsEvent {
        case onViewDidLoad, didTapClose, didTapTestPassword, didTapExportRecoveryKey, didTapExportRecoveryKeyCopyOKAlert, didTapProceedToLogout
        
        var eventIdentifier: any EventIdentifier {
            switch self {
            case .onViewDidLoad: PasswordReminderScreenEvent()
            case .didTapClose: PasswordReminderCloseButtonPressedEvent()
            case .didTapTestPassword: PasswordReminderTestPasswordButtonPressedEvent()
            case .didTapExportRecoveryKey: PasswordReminderExportRecoveryKeyButtonPressedEvent()
            case .didTapExportRecoveryKeyCopyOKAlert: PasswordReminderExportRecoveryKeyOkButtonPressedEvent()
            case .didTapProceedToLogout: PasswordReminderProceedToLogoutButtonPressedEvent()
            }
        }
    }
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackEvent(_ event: PasswordReminderAnalyticsEvent) {
        tracker.trackAnalyticsEvent(with: event.eventIdentifier)
    }
}
