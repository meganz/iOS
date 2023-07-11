@testable import MEGA
import MEGAAnalyticsiOS
import XCTest

final class PagerTabViewModelTests: XCTestCase {
    func testDidAppear_shouldTrackCurrentTabOnce() {
        let (sut, mockTracker) = makeSUT()
        
        sut.didAppear()

        mockTracker.assertTrackAnalyticsEventCalled(
            with: [sut.selectedTab.eventIdentifier]
        )
    }
    
    func testSetSelectedTab_shouldTrackTabEventForCurrentTab() {
        let (sut, mockTracker) = makeSUT()
        
        sut.selectedTab = .album

        mockTracker.assertTrackAnalyticsEventCalled(with: [AlbumsTabEvent()])
        
        sut.selectedTab = .timeline

        mockTracker.assertTrackAnalyticsEventCalled(
            with: [
                AlbumsTabEvent(),
                TimelineTabEvent()
            ]
        )
    }
    
    func testSetSelectedTab_shouldNotTrackTabEvent_whenTabNotChanged() {
        let (sut, mockTracker) = makeSUT()
        
        sut.selectedTab = .album

        mockTracker.assertTrackAnalyticsEventCalled(with: [AlbumsTabEvent()])
        
        sut.selectedTab = .album
        sut.selectedTab = .album
        sut.selectedTab = .album

        mockTracker.assertTrackAnalyticsEventCalled(with: [AlbumsTabEvent()])
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (PagerTabViewModel, MockTracker) {
        let mockAnalyticsTracker = MockTracker()
        let sut = PagerTabViewModel(tracker: mockAnalyticsTracker)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockAnalyticsTracker)
    }
}

private extension EventIdentifier {
    var stringValue: String {
        String(describing: type(of: self))
    }
}
