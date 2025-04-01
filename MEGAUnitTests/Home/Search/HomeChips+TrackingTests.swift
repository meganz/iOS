@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
import Search
import XCTest

final class HomeChipsTrackingTests: XCTestCase {
    func testTrackChip_trackingUnselectedChip_sendsResetEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity(type: .nodeFormat(.photo), title: "chip"), selected: false)

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchResetFilterPressedEvent()]
        )
    }
    
    func testTrackChip_trackingSelectedDocsChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.docs, selected: true)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchDocsFilterPressedEvent()]
        )
    }
    
    func testTrackChip_trackingSelectedVideosChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.video, selected: true)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchVideosFilterPressedEvent()]
        )
    }
    
    func testTrackChip_trackingSelectedImagesChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.images, selected: true)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchImageFilterPressedEvent()]
        )
    }
    
    func testTrackChip_trackingSelectedAudioChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.audio, selected: true)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [SearchAudioFilterPressedEvent()]
        )
    }
}
