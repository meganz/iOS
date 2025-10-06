@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

struct NodeActionResponderTests {

    @Test
    func hide() async throws {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.nodeActionListener()(.hide, [])

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                HideNodeMenuItemEvent()
            ]
        )
    }

    private func makeSUT(
        tracker: some AnalyticsTracking = MockTracker(),
        selectedNodesHandler: @escaping ([MEGANode]) -> Void = { _ in }
    ) -> NodeActionResponder {
        .init(tracker: tracker, selectedNodesHandler: selectedNodesHandler)
    }
}
