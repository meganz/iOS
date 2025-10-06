import MEGADomain

@MainActor
public final class MEGAPlayerViewModel {
    let player: any VideoPlayerProtocol
    var dismissAction: (() -> Void)?
    public var moreAction: (((any PlayableNode)?) -> Void)?
    let reportingManager: MEGAPlaybackReportingManager

    public init(
        player: some VideoPlayerProtocol
    ) {
        self.player = player
        self.reportingManager = MEGAPlaybackReportingManager(
            player: player,
            playbackReporter: DependencyInjection.playbackReporter,
            analyticsTracker: DependencyInjection.analyticsTracker
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
        reportingManager.recordOpenTimeStamp()
    }

    func viewDidDisappear() {
        player.stop()
    }

    func viewWillDismiss() {
        reportingManager.trackVideoPlaybackFinalEvents()
    }
}
