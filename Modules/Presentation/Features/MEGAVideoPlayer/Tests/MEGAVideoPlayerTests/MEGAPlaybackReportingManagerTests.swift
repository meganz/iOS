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
    func trackVideoPlaybackRecordEvent_whenHasStarted_shouldTrack() {
        let analyticsTracker = MockTracker()
        let sut = makeSUT(
            analyticsTracker: analyticsTracker
        )
        sut.recordOpenTimeStamp()
        sut.trackVideoPlaybackFinalEvents()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: analyticsTracker.trackedEventIdentifiers,
            with: [VideoPlaybackRecordNewVPEvent(duration: .anyTestValue)]
        )
    }

    @Test
    func trackVideoPlaybackRecordEvent_whenNotStarted_shouldNotTrack() {
        let analyticsTracker = MockTracker()
        let sut = makeSUT(
            analyticsTracker: analyticsTracker
        )
        sut.trackVideoPlaybackFinalEvents()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: analyticsTracker.trackedEventIdentifiers,
            with: []
        )
    }

    @Test
    func trackVideoPlaybackFirstFrameEvent_whenHasStartedAndIsPlaying_shouldTrack() async {
        let analyticsTracker = MockTracker()
        let player = MockVideoPlayer()
        let sut = makeSUT(
            player: player,
            analyticsTracker: analyticsTracker
        )
        sut.observePlayback()
        sut.recordOpenTimeStamp()
        player.state = .playing

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
