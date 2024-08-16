@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class HiddenFilesFoldersOnboardingViewModelTests: XCTestCase {
    func testOnViewAppear_called_shouldTrackTheCorrectEvent() {
        let screenEvents: [ScreenViewEventIdentifier] = [
            HideNodeOnboardingScreenEvent(),
            HideNodeUpgradeScreenEvent()]
        
        for screenEvent in screenEvents {
            let tracker = MockTracker()
            let sut = makeSUT(
                tracker: tracker,
                screenEvent: screenEvent)
            
            sut.onViewAppear()
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [screenEvent]
            )
        }
    }
    
    func testOnDismissButtonTapped_called_shouldTrackTheCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.onDismissButtonTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [HiddenNodeOnboardingCloseButtonPressedEvent()]
        )
    }

    private func makeSUT(
        tracker: some AnalyticsTracking = MockTracker(),
        screenEvent: some ScreenViewEventIdentifier = HideNodeOnboardingScreenEvent()
    ) -> HiddenFilesFoldersOnboardingViewModel {
        HiddenFilesFoldersOnboardingViewModel(
            tracker: tracker,
            screenEvent: screenEvent)
    }
}
