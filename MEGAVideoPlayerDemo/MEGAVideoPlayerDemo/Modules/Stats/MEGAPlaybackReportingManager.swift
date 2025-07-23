import Combine

@MainActor
final class MEGAPlaybackReportingManager {
    private var playbackStarted = false

    private var lastKnownState: PlaybackState?
    private var lastObservedTime: Duration?
    private var lastStalledTime: Duration?

    private var cancellables = Set<AnyCancellable>()

    private let playerOptionIdentifiable: any PlayerOptionIdentifiable
    private let playbackState: any PlaybackStateObservable
    private let playbackDebugMessage: any PlaybackDebugMessageObservable
    private let playbackReporter: any PlaybackReporting

    init(
        playerOptionIdentifiable: some PlayerOptionIdentifiable,
        playbackState: some PlaybackStateObservable,
        playbackDebugMessage: some PlaybackDebugMessageObservable,
        playbackReporter: some PlaybackReporting
    ) {
        self.playerOptionIdentifiable = playerOptionIdentifiable
        self.playbackState = playbackState
        self.playbackDebugMessage = playbackDebugMessage
        self.playbackReporter = playbackReporter
        playbackReporter.playbackPlayerOption(playerOptionIdentifiable.option)
    }

    convenience init(
        player: some VideoPlayerProtocol,
        playbackReporter: some PlaybackReporting
    ) {
        self.init(
            playerOptionIdentifiable: player,
            playbackState: player,
            playbackDebugMessage: player,
            playbackReporter: playbackReporter
        )
    }

    func observePlayback() {
        observeDebugMessage()
        observeState()
        observeCurrentTime()
    }

    private func observeDebugMessage() {
        playbackDebugMessage.debugMessagePublisher
            .sink { [weak self] in self?.newDebugMessage($0) }
            .store(in: &cancellables)
    }

    private func observeState() {
        playbackState.statePublisher
            .sink { [weak self] in self?.stateDidChange(to: $0) }
            .store(in: &cancellables)
    }

    private func observeCurrentTime() {
        playbackState.currentTimePublisher
            .sink { [weak self] in self?.currentTimeDidChange(to: $0) }
            .store(in: &cancellables)
    }

    private func newDebugMessage(_ message: String) {
        playbackReporter.playbackDebugMessage(message)
    }

    private func stateDidChange(to newState: PlaybackState) {
        if newState != lastKnownState {
            playbackReporter.playbackStateDidChange(newState)
            lastKnownState = newState
        }

        detectStalling(newState, with: playbackState.currentTime)
    }

    private func currentTimeDidChange(to newTime: Duration) {
        if !playbackStarted, playbackState.currentTime.components.seconds >= 0 {
            playbackStarted = true
            playbackReporter.playbackStarted()
        }

        playbackReporter.playbackCurrentTimeDidChange(playbackState.currentTime)

        detectStalling(playbackState.state, with: newTime)
    }

    /// Stalling is when playback has not progressed for a detectable period, indicating potential buffering or network-related delay.
    private func detectStalling(_ newState: PlaybackState, with currentTime: Duration) {
        guard playbackStarted else { return }

        switch newState {
        case .paused, .stopped, .ended, .error:
            break
        default:
            if currentTime == lastObservedTime, lastStalledTime == nil {
                lastStalledTime = currentTime
                playbackReporter.playbackStallStarted()
            } else if currentTime != lastObservedTime, lastStalledTime != nil {
                lastStalledTime = nil
                playbackReporter.playbackStallEnded()
            }
        }

        lastObservedTime = currentTime
    }
}
