@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class HiddenFilesFoldersOnboardingViewModelTests: XCTestCase {
    func testOnViewAppear_called_shouldTrackTheCorrectEvent() {
        let screenEvents: [any ScreenViewEventIdentifier] = [
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
        let dismissEvent = HiddenNodeOnboardingCloseButtonPressedEvent()
        let tracker = MockTracker()
        let sut = makeSUT(
            tracker: tracker,
            dismissEvent: dismissEvent)
        
        sut.onDismissButtonTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [dismissEvent]
        )
    }
    
    func testsViewConfiguration_init_shouldShowCorrectValues() {
        let showPrimaryButtonOnly = true
        let showNavigationBar = false
        
        let sut = makeSUT(
            showPrimaryButtonOnly: showPrimaryButtonOnly,
            showNavigationBar: showNavigationBar)
        
        XCTAssertEqual(sut.showPrimaryButtonOnly, showPrimaryButtonOnly)
        XCTAssertEqual(sut.showNavigationBar, showNavigationBar)
    }

    private func makeSUT(
        showPrimaryButtonOnly: Bool = false,
        showNavigationBar: Bool = true,
        tracker: some AnalyticsTracking = MockTracker(),
        screenEvent: (any ScreenViewEventIdentifier)? = nil,
        dismissEvent: (any ButtonPressedEventIdentifier)? = nil
    ) -> HiddenFilesFoldersOnboardingViewModel {
        HiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: showPrimaryButtonOnly,
            showNavigationBar: showNavigationBar,
            tracker: tracker,
            screenEvent: screenEvent, 
            dismissEvent: dismissEvent)
    }
}
