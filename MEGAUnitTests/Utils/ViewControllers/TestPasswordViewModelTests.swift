@testable import MEGA
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
import Testing

@MainActor
struct TestPasswordViewModelTests {

    @Suite("Track analytics events")
    struct TestPasswordAnalyticsEvents {
        struct TestCaseData: Sendable {
            var event: TestPasswordViewModel.TestPasswordAnalyticsEvent
            var expectedEventIdentifier: any EventIdentifier
        }
        
        @Test(arguments: [
            TestCaseData(event: .onViewDidLoad, expectedEventIdentifier: TestPasswordScreenEvent()),
            TestCaseData(event: .didTapConfirm, expectedEventIdentifier: TestPasswordConfirmButtonPressedEvent()),
            TestCaseData(event: .didShowWrongPassword, expectedEventIdentifier: TestPasswordConfirmWrongPasswordMessageDisplayedEvent()),
            TestCaseData(event: .didShowPasswordAccepted, expectedEventIdentifier: TestPasswordConfirmPasswordAcceptedMessageDisplayedEvent()),
            TestCaseData(event: .didTapExportRecoveryKey, expectedEventIdentifier: TestPasswordExportRecoveryKeyButtonPressedEvent()),
            TestCaseData(event: .didTapExportRecoveryKeyCopyOKAlert, expectedEventIdentifier: TestPasswordExportRecoveryKeyOkButtonPressedEvent()),
            TestCaseData(event: .didTapProceedToLogout, expectedEventIdentifier: TestPasswordProceedToLogoutButtonPressedEvent())
        ])
        @MainActor func trackCorrectAnalyticsEvent(testCase: TestCaseData) {
            let tracker = MockTracker()
            let sut = TestPasswordViewModel(tracker: tracker)
            
            sut.trackEvent(testCase.event)
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testCase.expectedEventIdentifier]
            )
        }
    }

}
