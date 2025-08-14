@MainActor
public final class MEGAPlayerViewModel {
    let player: any VideoPlayerProtocol
    var dismissAction: (() -> Void)?
    let reportingManager: MEGAPlaybackReportingManager

    public init(
        player: some VideoPlayerProtocol
    ) {
        self.player = player
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
