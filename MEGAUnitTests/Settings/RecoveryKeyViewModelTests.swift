@testable import MEGA
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import MEGATest
import Testing

struct RecoveryKeyViewModelTests {
    // MARK: - Helper
    @MainActor
    private static func makeSUT(
        isLoggedIn: Bool = true,
        tracker: some AnalyticsTracking = MockTracker(),
        router: some RecoveryKeyViewRouting = MockRecoveryKeyViewRouter()
    ) -> RecoveryKeyViewModel {
        let sut = RecoveryKeyViewModel(
            accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn),
            saveMasterKeyCompletion: nil,
            tracker: tracker,
            router: router
        )
        return sut
    }

    // MARK: - Tests
    @Suite("Track analytics events")
    struct RecoveryKeyAnalyticsEvents {
        struct TestCaseData {
            var action: RecoveryKeyAction
            var expectedEventIdentifier: any EventIdentifier
        }
        
        @Test(arguments: [
            TestCaseData(action: .onViewDidLoad, expectedEventIdentifier: RecoveryKeyScreenEvent()),
            TestCaseData(action: .didTapCopyButton, expectedEventIdentifier: RecoveryKeyCopyButtonPressedEvent()),
            TestCaseData(action: .didTapCopyOkAlertButton, expectedEventIdentifier: RecoveryKeyCopyOkButtonPressedEvent()),
            TestCaseData(action: .didTapSaveButton, expectedEventIdentifier: RecoveryKeySaveButtonPressedEvent()),
            TestCaseData(action: .didTapSaveOkAlertButton, expectedEventIdentifier: RecoveryKeySaveOkButtonPressedEvent()),
            TestCaseData(action: .didTapWhyDoINeedARecoveryKey, expectedEventIdentifier: RecoveryKeyWhyDoINeedARecoveryKeyButtonPressedEvent())
        ])
        @MainActor func trackCorrectAnalyticsEvent(testCase: TestCaseData) {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            sut.dispatch(testCase.action)
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testCase.expectedEventIdentifier]
            )
        }
    }
    
    @Suite("Test dispatch actions")
    struct RecoveryKeyDispatchActions {
        
        @Test("Only perform copy action if there is a logged in user",
              arguments: [true, false])
        @MainActor func invokeCopy(isLoggedIn: Bool) {
            let sut = makeSUT(isLoggedIn: isLoggedIn)
            
            sut.dispatch(.didTapCopyButton)
            let isCopyTriggered = sut.copyMasterKeyTask != nil
            
            #expect(isCopyTriggered == isLoggedIn)
        }
        
        @Test("Only perform save action if there is a logged in user and existing ViewController",
              arguments: [
                (isLoggedIn: true, withViewController: true, expectedResult: true),
                (isLoggedIn: false, withViewController: false, expectedResult: false),
                (isLoggedIn: true, withViewController: false, expectedResult: false)
              ])
        @MainActor func invokeSave(isLoggedIn: Bool, withViewController: Bool, expectedResult: Bool) {
            let router = MockRecoveryKeyViewRouter(
                recoveryKeyViewController: withViewController ? UIViewController() : nil
            )
            let sut = makeSUT(isLoggedIn: isLoggedIn, router: router)
            
            sut.dispatch(.didTapSaveButton)
            let isSaveTriggered = sut.saveMasterKeyTask != nil
            
            #expect(isSaveTriggered == expectedResult)
        }
        
        @Test("Show security link on tapping Why Do I Need A Recovery Key button")
        @MainActor func invokeWhyDoINeedARecoveryKeySecurityLink() {
            let router = MockRecoveryKeyViewRouter()
            let sut = makeSUT(router: router)
            
            sut.dispatch(.didTapWhyDoINeedARecoveryKey)
            
            #expect(router.showSecurityLink_calledTimes == 1)
        }
    }
}
