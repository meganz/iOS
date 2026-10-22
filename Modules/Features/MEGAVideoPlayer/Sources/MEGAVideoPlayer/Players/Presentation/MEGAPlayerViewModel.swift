import MEGADomain

@MainActor
public final class MEGAPlayerViewModel {
    var player: any VideoPlayerProtocol
    var dismissAction: (() -> Void)?
    /// Runs first when the current node is deleted, before playback ends and the screen is dismissed
    var nodeDeletedAction: (() -> Void)?
    public var moreAction: (((any PlayableNode)?) -> Void)?
    /// Runs once as playback starts, before the player takes the lock screen / Control Center commands.
    public var onPlaybackStarted: (() -> Void)?
    /// Runs once playback has ended for good — the screen is dismissed and any Picture in Picture session is over.
    public var onPlaybackEnded: (() -> Void)?
    let reportingManager: MEGAPlaybackReportingManager
    private let nowPlayingController: VideoNowPlayingController
    private(set) var hasEndedPlayback = false

    public convenience init(
        player: some VideoPlayerProtocol
    ) {
        self.init(player: player, nowPlayingController: VideoNowPlayingController(player: player))
    }

    init(
        player: some VideoPlayerProtocol,
        nowPlayingController: VideoNowPlayingController
    ) {
        self.player = player
        self.nowPlayingController = nowPlayingController
        self.reportingManager = MEGAPlaybackReportingManager(
            player: player,
            playbackReporter: DependencyInjection.playbackReporter,
            analyticsTracker: DependencyInjection.analyticsTracker
        )
    }

    func viewDidLayoutSubviews(playerView: any PlayerViewProtocol) {
        player.resizePlayer(to: playerView.bounds)
    }

    func viewDidLoad(playerView: any PlayerViewProtocol) {
        reportingManager.observePlayback()
        player.setupPlayer(in: playerView)
        reportingManager.recordOpenTimeStamp()
        // Before taking the shared commands: whoever steps back for this player disables them as it goes
        onPlaybackStarted?()
        nowPlayingController.start()
        setupNodeDeletionHandling()
    }
    
    private func setupNodeDeletionHandling() {
        player.onNodeDeleted = { [weak self] in
            // A deleted node has nothing left to play, so playback ends here rather than only the screen going away.
            self?.nodeDeletedAction?()
            self?.viewWillDismiss()
            self?.dismissAction?()
        }
    }

    /// Ends playback for good. Runs once: a Picture in Picture session ending can ask for it again after it already ran,
    /// which would otherwise report the final playback events twice.
    func viewWillDismiss() {
        guard !hasEndedPlayback else { return }
        hasEndedPlayback = true

        reportingManager.trackVideoPlaybackFinalEvents()
        nowPlayingController.stop()
        player.stop()
        onPlaybackEnded?()
    }
}
