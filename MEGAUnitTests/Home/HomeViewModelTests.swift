@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class HomeViewModelTests: XCTestCase {
    func testDidStartSearchSession_tracksAnalyticsEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModel(
            shareUseCase: MockShareUseCase(),
            tracker: tracker
        )
        sut.didStartSearchSession()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                HomeScreenSearchMenuToolbarEvent()
            ]
        )
    }
    
    func testStartConversation_onButtonTapped_tracksAnalyticsEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModel(
            shareUseCase: MockShareUseCase(),
            tracker: tracker
        )
        
        sut.didTapStartConversationButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                IOSStartConversationButtonEvent()
            ]
        )
    }
    
    func testStartUploadFile_onButtonTapped_tracksAnalyticsEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModel(
            shareUseCase: MockShareUseCase(),
            tracker: tracker
        )
        
        sut.didTapUploadFilesButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                IOSUploadFilesButtonEvent()
            ]
        )
    }
}
