@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGATest
import XCTest

@MainActor
final class PagerTabViewModelTests: XCTestCase {
    func testDidAppear_shouldTrackCurrentTabOnce() {
        let (sut, mockTracker) = makeSUT()
        
        sut.didAppear()

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [sut.selectedTab.eventIdentifier]
        )
    }
    
    func testSetSelectedTab_shouldTrackTabEventForCurrentTab() {
        let (sut, mockTracker) = makeSUT()
        
        sut.selectedTab = .album

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [AlbumsTabEvent()]
        )
        
        sut.selectedTab = .timeline

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                AlbumsTabEvent(),
                TimelineTabEvent()
            ]
        )
    }
    
    func testSetSelectedTab_shouldNotTrackTabEvent_whenTabNotChanged() {
        let (sut, mockTracker) = makeSUT()
        
        sut.selectedTab = .album

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [AlbumsTabEvent()]
        )
        
        sut.selectedTab = .album
        sut.selectedTab = .album
        sut.selectedTab = .album

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [AlbumsTabEvent()]
        )
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (PagerTabViewModel, MockTracker) {
        let mockAnalyticsTracker = MockTracker()
        let sut = PagerTabViewModel(tracker: mockAnalyticsTracker)
        return (sut, mockAnalyticsTracker)
    }
}

private extension EventIdentifier {
    var stringValue: String {
        String(describing: type(of: self))
    }
}
