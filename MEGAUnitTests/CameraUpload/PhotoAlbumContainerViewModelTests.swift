@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentationMock
import MEGATest
import XCTest

final class PhotoAlbumContainerViewModelTests: XCTestCase {
    
    func testDidAppear_shouldTrackPhotoScreenViewEvent() {
        let mockTracker = MockTracker()
        let sut = PhotoAlbumContainerViewModel(tracker: mockTracker)
        
        sut.didAppear()

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [PhotoScreenEvent()]
        )
    }
    
    func testShareLinksTapped_shouldSetShowShareAlbumLinksToTrueAndTrackEvent() {
        let mockTracker = MockTracker()
        let sut = PhotoAlbumContainerViewModel(tracker: mockTracker)
        
        sut.shareLinksTapped()
        
        XCTAssertTrue(sut.showShareAlbumLinks)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [AlbumListShareLinkMenuItemEvent()]
        )
    }
}
