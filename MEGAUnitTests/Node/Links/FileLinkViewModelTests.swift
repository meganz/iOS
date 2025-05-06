@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
import Testing

@MainActor
@Suite("FileLinkViewModel")
struct FileLinkViewModelTests {
    @MainActor
    struct Harness {
        var sut: FileLinkViewModel
        var tracker: MockTracker
        
        init() {
            let tracker = MockTracker()
            self.tracker = tracker
            self.sut = FileLinkViewModel(tracker: tracker)
            
        }
    }
    
    @Test("Send to chat file link")
    func testTrackSendToChatFileLink() {
        let harness = Harness()
        harness.sut.dispatch(.trackSendToChatFileLink)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers, with: [SendToChatFileLinkButtonPressedEvent()])
    }
    
    @Test("Send to chat file link no account logged")
    func testTrackSendToChatFileLinkNoAccountLogged() {
        let harness = Harness()
        harness.sut.dispatch(.trackSendToChatFileLinkNoAccountLogged)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers, with: [SendToChatFileLinkNoAccountLoggedButtonPressedEvent()])
    }
}
