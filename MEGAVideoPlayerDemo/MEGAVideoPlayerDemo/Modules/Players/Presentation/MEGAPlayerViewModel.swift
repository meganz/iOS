@MainActor
final class MEGAPlayerViewModel {
    let player: any VideoPlayerProtocol

    init(player: some VideoPlayerProtocol) {
        self.player = player
    }

    func viewDidLayoutSubviews(playerLayer: any PlayerLayerProtocol) {
        player.resizePlayer(to: playerLayer.bounds)
    }

    func viewWillAppear() {
        player.play()
    }

    func viewDidLoad(playerLayer: any PlayerLayerProtocol) {
        player.setupPlayer(in: playerLayer)
    }

    func viewDidDisappear() {
        player.stop()
    }
}
