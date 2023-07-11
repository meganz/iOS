@testable import MEGA
import MEGAAnalyticsiOS
import XCTest

final class PhotoAlbumContainerViewModelTests: XCTestCase {
    
    func testDidAppear_shouldTrackPhotoScreenViewEvent() {
        let mockTracker = MockTracker()
        let sut = PhotoAlbumContainerViewModel(tracker: mockTracker)
        
        sut.didAppear()

        mockTracker.assertTrackAnalyticsEventCalled(with: [PhotoScreenEvent()])
    }
    
}
