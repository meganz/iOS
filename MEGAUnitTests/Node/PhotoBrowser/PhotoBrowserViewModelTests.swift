@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class PhotoBrowserViewModelTests: XCTestCase {
    
    func testOnViewDidLoad_called_shouldTrackPhotoPreviewEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.onViewDidLoad()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoPreviewScreenEvent()])
    }
    
    func testTrackAnalyticsSaveToDeviceMenuToolbarEvent_called_shouldTrackCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.trackAnalyticsSaveToDeviceMenuToolbarEvent()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoPreviewSaveToDeviceMenuToolbarEvent()])
    }
    
    func testTrackHideNodeMenuEvent_called_shouldTrackCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.trackHideNodeMenuEvent()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [ImagePreviewHideNodeMenuToolBarEvent()])
    }
    
    private func makeSUT(
        tracker: some AnalyticsTracking = MockTracker()
    ) -> PhotoBrowserViewModel {
        PhotoBrowserViewModel(tracker: tracker)
    }
}
