@MainActor
public final class MEGAPlayerViewModel {
    let player: any VideoPlayerProtocol
    var onDismiss: (() -> Void)? = nil
    let reportingManager: MEGAPlaybackReportingManager

    public init(
        player: some VideoPlayerProtocol,
        onDismiss: (() -> Void)? = nil
    ) {
        self.player = player
        self.onDismiss = onDismiss
        self.reportingManager = MEGAPlaybackReportingManager(
            player: player,
            playbackReporter: DependencyInjection.playbackReporter
        )
    }

    func viewDidLayoutSubviews(playerLayer: any PlayerLayerProtocol) {
        player.resizePlayer(to: playerLayer.bounds)
    }

    func viewWillAppear() {
        player.play()
    }

    func viewDidLoad(playerLayer: any PlayerLayerProtocol) {
        reportingManager.observePlayback()
        player.setupPlayer(in: playerLayer)
    }

    func viewDidDisappear() {
        player.stop()
    }
}
