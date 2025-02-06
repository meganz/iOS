@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

@MainActor
final class InitialLaunchViewModelTests: XCTestCase {
    func testDispatch_didTapSetUpMEGAButton_shouldTrackSetUpMEGAButtonTappedEvent() {
        assertDispatchTracksEvent(
            action: .didTapSetUpMEGAButton,
            expectedEvent: InitialLaunchSetUpButtonPressedEvent()
        )
    }
    
    func testDispatch_didTapSkipSetUpButton_shouldTrackSkipSetUpButtonTappedEvent() {
        assertDispatchTracksEvent(
            action: .didTapSkipSetUpButton,
            expectedEvent: InitialLaunchSkipSetUpButtonPressedEvent()
        )
    }
    
    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (InitialLaunchViewModel, MockTracker) {
        let tracker = MockTracker()
        let sut = InitialLaunchViewModel(tracker: tracker)
        trackForMemoryLeaks(
            on: sut,
            file: file,
            line: line
        )
        return (sut, tracker)
    }
    
    private func assertDispatchTracksEvent(
        action: InitialLaunchAction,
        expectedEvent: any EventIdentifier
    ) {
        let (sut, tracker) = makeSUT()
        sut.dispatch(action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }
}
