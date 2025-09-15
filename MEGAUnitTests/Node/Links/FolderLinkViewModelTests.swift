@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import MEGATest
import Testing

@MainActor
@Suite("FolderLinkViewModel")
struct FolderLinkViewModelTests {
    @MainActor
    struct Harness {
        var sut: FolderLinkViewModel
        var tracker: MockTracker
        
        init() {
            let tracker = MockTracker()
            self.tracker = tracker
            self.sut = FolderLinkViewModel(
                folderLinkUseCase: MockFolderLinkUseCase(),
                saveMediaUseCase: MockSaveMediaToPhotosUseCase(),
                tracker: tracker
            )
        }
    }
    
    @Test("Send to chat folder link")
    func testTrackSendToChatFolderLink() {
        let harness = Harness()
        harness.sut.dispatch(.trackSendToChatFolderLink)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers, with: [SendToChatFolderLinkButtonPressedEvent()])
    }
    
    @Test("Send to chat folder link no account logged")
    func testTrackSendToChatFolderLinkNoAccountLogged() {
        let harness = Harness()
        harness.sut.dispatch(.trackSendToChatFolderLinkNoAccountLogged)

        Test.assertTrackAnalyticsEventCalled(trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers, with: [SendToChatFolderLinkNoAccountLoggedButtonPressedEvent()])
    }
}
