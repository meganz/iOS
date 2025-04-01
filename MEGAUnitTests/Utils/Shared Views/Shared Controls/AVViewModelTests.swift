@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import XCTest

final class AVViewModelTests: XCTestCase {

    func testOnViewDidLoad_called_shouldTrackPhotoPreviewEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.onViewDidLoad()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [VideoPlayerScreenEvent()])
    }

    private func makeSUT(
        tracker: some AnalyticsTracking = MockTracker()
    ) -> AVViewModel {
        AVViewModel(tracker: tracker)
    }
}
