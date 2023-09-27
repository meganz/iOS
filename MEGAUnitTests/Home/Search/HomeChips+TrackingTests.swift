@testable import MEGA
import MEGAAnalyticsiOS
import MEGAPresentation
import Search
import XCTest

final class HomeChipsTrackingTests: XCTestCase {
    func testTrackChip_trackingUnselectedChip_sendsResetEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity(id: 1, title: "chip"), selected: false)
        tracker.assertTrackAnalyticsEventCalled(with: [SearchResetFilterPressedEvent()])
    }
    
    func testTrackChip_trackingSelectedDocsChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.docs, selected: true)
        tracker.assertTrackAnalyticsEventCalled(with: [SearchDocsFilterPressedEvent()])
    }
    
    func testTrackChip_trackingSelectedVideosChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.video, selected: true)
        tracker.assertTrackAnalyticsEventCalled(with: [SearchVideosFilterPressedEvent()])
    }
    
    func testTrackChip_trackingSelectedImagesChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.images, selected: true)
        tracker.assertTrackAnalyticsEventCalled(with: [SearchImageFilterPressedEvent()])
    }
    
    func testTrackChip_trackingSelectedAudioChip_sendsDocsEvent() {
        let tracker = MockTracker()
        tracker.trackChip(tapped: SearchChipEntity.audio, selected: true)
        tracker.assertTrackAnalyticsEventCalled(with: [SearchAudioFilterPressedEvent()])
    }
}
