@MainActor
public final class MEGAPlayerViewModel {
    let player: any VideoPlayerProtocol
    var dismissAction: (() -> Void)?
    public var moreAction: (() -> Void)?
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

    func viewDidLayoutSubviews(playerView: any PlayerViewProtocol) {
        player.resizePlayer(to: playerView.bounds)
    }

    func viewWillAppear() {
        player.play()
    }

    func viewDidLoad(playerView: any PlayerViewProtocol) {
        reportingManager.observePlayback()
        player.setupPlayer(in: playerView)
    }

    func viewDidDisappear() {
        player.stop()
    }
}
