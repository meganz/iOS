import AVFoundation

@MainActor
final class MEGAAVPlayer: MEGABasePlayer {
    private let player = AVPlayer()
    private var playerItemContext = 0
    private var timeObserverToken: Any?
    private var playerLayer: AVPlayerLayer?

    override init(streamingUseCase: some StreamingUseCaseProtocol) {
        super.init(streamingUseCase: streamingUseCase)
        setupObservers()
    }

    deinit {
        player.removeObserver(self, forKeyPath: "rate", context: &playerItemContext)
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemContext)
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }
}

extension MEGAAVPlayer: PlaybackControllable {
    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        streamingUseCase.stopStreaming()
    }

    func jumpForward(by seconds: TimeInterval) {
        guard player.currentItem != nil else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        seek(to: newTime)
    }

    func jumpBackward(by seconds: TimeInterval) {
        guard player.currentItem != nil else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeGetSeconds(currentTime) - seconds
        seek(to: max(newTime, 0))
    }

    func seek(to time: TimeInterval) {
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: newTime)
    }
}

extension MEGAAVPlayer: VideoRenderable {
    func setupPlayer(in playerLayer: any PlayerLayerProtocol) {
        if let existingLayer = self.playerLayer {
            existingLayer.removeFromSuperlayer()
        }

        let newLayer = AVPlayerLayer(player: player)
        newLayer.frame = playerLayer.bounds
        newLayer.videoGravity = .resizeAspect
        playerLayer.layer.addSublayer(newLayer)
        self.playerLayer = newLayer
    }

    func resizePlayer(to frame: CGRect) {
        playerLayer?.frame = frame
    }
}

extension MEGAAVPlayer: NodeLoadable {
    func loadNode(_ node: any PlayableNode) {
        if !streamingUseCase.isStreaming {
            streamingUseCase.startStreaming()
        }

        guard let url = streamingUseCase.streamingLink(for: node) else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.state = .ended
            }
        }

        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: &playerItemContext)
        observeTimeChanges()
    }
}

extension MEGAAVPlayer {
    static func liveValue(
        node: any PlayableNode
    ) -> MEGAAVPlayer {
        let player = MEGAAVPlayer(streamingUseCase: DependencyInjection.streamingUseCase)
        player.loadNode(node)
        return player
    }

    static var liveValue: MEGAAVPlayer {
        MEGAAVPlayer(streamingUseCase: DependencyInjection.streamingUseCase)
    }
}

extension MEGAAVPlayer {
    private func observeTimeChanges() {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }

            DispatchQueue.main.async {
                self.currentTime = .seconds(CMTimeGetSeconds(time))
                if let duration = self.player.currentItem?.duration {
                    self.duration = .seconds(CMTimeGetSeconds(duration))
                }
            }
        }
    }

    func setupObservers() {
        player.addObserver(self, forKeyPath: "rate", options: [.new, .initial], context: &playerItemContext)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == "rate" {
            let newRate = player.rate
            if player.currentItem == nil {
                state = .stopped
            } else if newRate == 0 {
                state = .paused
            } else {
                state = .playing
            }
        }

        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    state = .playing
                case .failed:
                    state = .error
                case .unknown:
                    state = .buffering
                @unknown default:
                    break
                }
            }
        }
    }
}
