import MEGAAnalyticsiOS
import MEGAPresentation

final class PasswordReminderViewModel: NSObject {
    enum PasswordReminderAnalyticsEvent {
        case onViewDidLoad, didTapClose, didTapTestPassword, didTapExportRecoveryKey, didTapExportRecoveryKeyCopyOKAlert, didTapProceedToLogout
    }
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackEvent(_ event: PasswordReminderAnalyticsEvent) {
        switch event {
        case .onViewDidLoad:
            tracker.trackAnalyticsEvent(with: PasswordReminderScreenEvent())
        case .didTapClose:
            tracker.trackAnalyticsEvent(with: PasswordReminderCloseButtonPressedEvent())
        case .didTapTestPassword:
            tracker.trackAnalyticsEvent(with: PasswordReminderTestPasswordButtonPressedEvent())
        case .didTapExportRecoveryKey:
            tracker.trackAnalyticsEvent(with: PasswordReminderExportRecoveryKeyButtonPressedEvent())
        case .didTapExportRecoveryKeyCopyOKAlert:
            tracker.trackAnalyticsEvent(with: PasswordReminderExportRecoveryKeyOkButtonPressedEvent())
        case .didTapProceedToLogout:
            tracker.trackAnalyticsEvent(with: PasswordReminderProceedToLogoutButtonPressedEvent())
        }
    }
}
