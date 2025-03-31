@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import Testing

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {
    @Test
    @MainActor
    func didStartSearchSession_tracksAnalyticsEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.didStartSearchSession()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                HomeScreenSearchMenuToolbarEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func startConversation_onButtonTapped_tracksAnalyticsEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.didTapStartConversationButton()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                IOSStartConversationButtonEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func startUploadFile_onButtonTapped_tracksAnalyticsEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.didTapUploadFilesButton()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                IOSUploadFilesButtonEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func screenEvent() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.trackHomeScreenEvent()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                HomeScreenEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func hideNodeAction() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.trackHideNodeAction()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                HideNodeMenuItemEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func smartBannerViewDidScroll() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.trackDidScrollSmartBannerView()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                SmartBannerSwipeEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func didTapVPNSmartBanner() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.trackDidTapVPNSmartBanner()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                VpnSmartBannerItemSelectedEvent()
            ]
        )
    }
    
    @Test
    @MainActor
    func didTapPWMSmartBanner() {
        let tracker = MockTracker()
        let sut = HomeViewModelTests.makeSUT(
            tracker: tracker
        )
        
        sut.trackDidTapPWMSmartBanner()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                PwmSmartBannerItemSelectedEvent()
            ]
        )
    }

    @MainActor
    private static func makeSUT(
        shareUseCase: any ShareUseCaseProtocol = MockShareUseCase(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> HomeViewModel {
        .init(
            shareUseCase: shareUseCase,
            tracker: tracker
        )
    }
}
