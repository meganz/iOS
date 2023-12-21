@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class PhotoAlbumContainerViewModelTests: XCTestCase {
    
    func testDidAppear_shouldTrackPhotoScreenViewEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.didAppear()

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoScreenEvent()]
        )
    }
    
    func testShareLinksTapped_shouldSetShowShareAlbumLinksToTrueAndTrackEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.shareLinksTapped()
        
        XCTAssertTrue(sut.showShareAlbumLinks)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AlbumListShareLinkMenuItemEvent()]
        )
    }
    
    func testShowToolbar_onEditModeUpdate_shouldChange() {
        let sut = makeSUT()
        XCTAssertFalse(sut.showToolbar)
        
        sut.editMode = .active
        XCTAssertTrue(sut.showToolbar)
        
        sut.editMode = .inactive
        XCTAssertFalse(sut.showToolbar)
    }
    
    private func makeSUT(tracker: some AnalyticsTracking = MockTracker(),
                         file: StaticString = #file,
                         line: UInt = #line
    ) -> PhotoAlbumContainerViewModel {
       let sut = PhotoAlbumContainerViewModel(tracker: tracker)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
