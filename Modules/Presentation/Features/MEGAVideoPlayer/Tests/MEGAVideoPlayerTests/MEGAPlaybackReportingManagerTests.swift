import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGATest
@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing

@MainActor
struct MEGAPlaybackReportingManagerTests {
    @Test
    func trackVideoPlaybackRecordEvent_whenItemIsReadyToPlay_shouldTrack() async {
        let player = MockVideoPlayer()
        let analyticsTracker = MockTracker()
        let sut = makeSUT(
            player: player,
            analyticsTracker: analyticsTracker
        )
        sut.observePlayback()
        sut.recordOpenTimeStamp()
        player.itemStatus = .readyToPlay

        // Wait for itemStatus to be readyToPlay
        for await _ in player.itemStatusPublisher.values {
            break
        }

        sut.trackVideoPlaybackFinalEvents()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: analyticsTracker.trackedEventIdentifiers,
            with: [
                VideoPlaybackFirstFrameNewVPEvent(
                    time: .anyTestValue,
                    scenario: VideoPlaybackFirstFrameNewVP.VideoPlaybackScenario.manualclick,
                    commonMap: ""),
                VideoPlaybackRecordNewVPEvent(duration: .anyTestValue),
                VideoPlaybackStallNewVPEvent(
                    time: .anyTestValue,
                    scenario: VideoPlaybackStallNewVP.VideoPlaybackScenario.manualclick,
                    commonMap: ""
                )
            ]
        )
    }

    @Test
    func trackVideoPlaybackRecordEvent_whenNotStarted_shouldTrackFailureEvent() {
        let analyticsTracker = MockTracker()
        let sut = makeSUT(
            analyticsTracker: analyticsTracker
        )
        sut.trackVideoPlaybackFinalEvents()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: analyticsTracker.trackedEventIdentifiers,
            with: [VideoPlaybackStartupFailureNewVPEvent(
                scenario: VideoPlaybackStartupFailureNewVP.VideoPlaybackScenario.manualclick,
                commonMap: "")]
        )
    }

    @Test
    func trackVideoPlaybackFirstFrameEvent_whenItemIsReadyToPlay_shouldTrack() async {
        let analyticsTracker = MockTracker()
        let player = MockVideoPlayer()
        let sut = makeSUT(
            player: player,
            analyticsTracker: analyticsTracker
        )
        sut.observePlayback()
        sut.recordOpenTimeStamp()
        player.itemStatus = .readyToPlay

        // Wait for itemStatus to be readyToPlay
        for await _ in player.itemStatusPublisher.values {
            break
        }

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: analyticsTracker.trackedEventIdentifiers,
            with: [VideoPlaybackFirstFrameNewVPEvent(
                time: .anyTestValue,
                scenario: VideoPlaybackFirstFrameNewVP.VideoPlaybackScenario.manualclick,
                commonMap: "")
            ]
        )
    }

    @Test
    func trackVideoPlaybackFirstFrameEvent_whenError_shouldTrack() async {
        let analyticsTracker = MockTracker()
        let player = MockVideoPlayer()
        let sut = makeSUT(
            player: player,
            analyticsTracker: analyticsTracker
        )
        sut.observePlayback()
        player.state = .error("")

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: analyticsTracker.trackedEventIdentifiers,
            with: [VideoPlaybackStartupFailureNewVPEvent(
                scenario: VideoPlaybackStartupFailureNewVP.VideoPlaybackScenario.manualclick,
                commonMap: "")
            ]
        )
    }

    // MARK: Helper

    private func makeSUT(
        player: some VideoPlayerProtocol = MockVideoPlayer(),
        playbackReporter: some PlaybackReporting = MEGALogPlaybackReporter(),
        analyticsTracker: some AnalyticsTracking = MockTracker()
    ) -> MEGAPlaybackReportingManager {
        MEGAPlaybackReportingManager(
            player: player,
            playbackReporter: playbackReporter,
            analyticsTracker: analyticsTracker)
    }
}

private extension Int32 {
    static let anyTestValue: Self = 1
}
