@testable import MEGA
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
import Testing

@MainActor
struct PasswordReminderViewModelTests {

    @Suite("Track analytics events")
    struct PasswordReminderAnalyticsEvents: Sendable {
        struct TestCaseData {
            var event: PasswordReminderViewModel.PasswordReminderAnalyticsEvent
            var expectedEventIdentifier: any EventIdentifier
        }
        
        @Test(arguments: [
            TestCaseData(event: .onViewDidLoad, expectedEventIdentifier: PasswordReminderScreenEvent()),
            TestCaseData(event: .didTapClose, expectedEventIdentifier: PasswordReminderCloseButtonPressedEvent()),
            TestCaseData(event: .didTapTestPassword, expectedEventIdentifier: PasswordReminderTestPasswordButtonPressedEvent()),
            TestCaseData(event: .didTapExportRecoveryKey, expectedEventIdentifier: PasswordReminderExportRecoveryKeyButtonPressedEvent()),
            TestCaseData(event: .didTapExportRecoveryKeyCopyOKAlert, expectedEventIdentifier: PasswordReminderExportRecoveryKeyOkButtonPressedEvent()),
            TestCaseData(event: .didTapProceedToLogout, expectedEventIdentifier: PasswordReminderProceedToLogoutButtonPressedEvent())
        ])
        @MainActor func trackCorrectAnalyticsEvent(testCase: TestCaseData) {
            let tracker = MockTracker()
            let sut = PasswordReminderViewModel(tracker: tracker)
            
            sut.trackEvent(testCase.event)
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testCase.expectedEventIdentifier]
            )
        }
    }
}
