import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

/// Where the track's bytes come from
extension PlaybackTrack {
    var analyticsSourceType: String {
        switch self {
        case .account: "account"
        case .folderLink: "folderLink"
        case .fileLink: "fileLink"
        case .offline: "offline"
        case .offlineNode: "offlineNode"
        }
    }
}

/// Sends the two playback events and keeps them honest per attempt: one
/// `AudioPlaybackStarted` and at most one `AudioPlaybackFailed` for any given
/// `playGeneration`, so a retried or superseded attempt cannot inflate either count.
@MainActor
final class AudioPlaybackAnalyticsReporter {
    private let tracker: any AnalyticsTracking
    private let accountUseCase: any AccountUseCaseProtocol

    private var startedGeneration: Int?
    private var failedGeneration: Int?

    init(
        tracker: some AnalyticsTracking,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.tracker = tracker
        self.accountUseCase = accountUseCase
    }

    func trackPlaybackStarted(track: PlaybackTrack, generation: Int) {
        guard startedGeneration != generation else { return }
        startedGeneration = generation

        tracker.trackAnalyticsEvent(
            with: AudioPlaybackStartedEvent(
                sourceType: track.analyticsSourceType,
                authStatus: accountUseCase.isLoggedIn() ? .loggedin : .loggedout
            )
        )
    }

    /// `track` is nil only when the failure is that there was no track to play,
    /// which has no fetch path to attribute.
    func trackPlaybackFailed(
        track: PlaybackTrack?,
        reason: AudioPlaybackFailureReason,
        generation: Int
    ) {
        guard failedGeneration != generation else { return }
        failedGeneration = generation

        tracker.trackAnalyticsEvent(
            with: AudioPlaybackFailedEvent(
                sourceType: track?.analyticsSourceType ?? "none",
                reason: reason.rawValue,
                authStatus: accountUseCase.isLoggedIn() ? .loggedin : .loggedout
            )
        )
    }
}
