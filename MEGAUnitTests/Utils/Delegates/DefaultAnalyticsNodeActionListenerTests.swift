@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

struct DefaultAnalyticsNodeActionListenerTests {

    @Test
    func hide() async throws {
        let tracker = MockTracker()
        let sut = DefaultAnalyticsNodeActionListenerTests
            .makeSUT(tracker: tracker)
        
        sut.nodeActionListener()(.hide)
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                HideNodeMenuItemEvent()
            ]
        )
    }

    private static func makeSUT(
        tracker: some AnalyticsTracking = MockTracker()
    ) -> DefaultAnalyticsNodeActionListener {
        .init(tracker: tracker)
    }
}
