import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class PhotoLibraryContentViewRouterTests: XCTestCase {
    @MainActor
    func testOpenPhotoBrowser_photoSelected_shouldTrackSinglePhotoEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.openPhotoBrowser(for: NodeEntity(handle: 1),
                             allPhotos: [])
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoItemSelectedEvent(selectionType: .single)])
    }
    
    @MainActor
    private func makeSUT(
        contentMode: PhotoLibraryContentMode = .library,
        tracker: some AnalyticsTracking = MockTracker()
    ) -> PhotoLibraryContentViewRouter {
        PhotoLibraryContentViewRouter(
            contentMode: contentMode,
            tracker: tracker
        )
    }
}
