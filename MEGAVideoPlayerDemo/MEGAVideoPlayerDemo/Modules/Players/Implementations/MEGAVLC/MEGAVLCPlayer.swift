import MobileVLCKit

@MainActor
final class MEGAVLCPlayer: MEGABasePlayer {
    private var media: VLCMedia? {
        didSet { player.media = media }
    }

    private let player = VLCMediaPlayer()

    override init(streamingUseCase: some StreamingUseCaseProtocol) {
        super.init(streamingUseCase: streamingUseCase)
        player.delegate = self
    }
}

extension MEGAVLCPlayer: PlaybackControllable {
    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
        streamingUseCase.stopStreaming()
    }

    func jumpForward(by seconds: TimeInterval) {
        player.jumpForward(Int32(seconds))
    }

    func jumpBackward(by seconds: TimeInterval) {
        player.jumpBackward(Int32(seconds))
    }

    func seek(to time: TimeInterval) {
        guard let media else { return }

        player.position = Float(time / Double(media.length.intValue))
    }
}

extension MEGAVLCPlayer: NodeLoadable {
    func loadNode(_ node: any PlayableNode) {
        if !streamingUseCase.isStreaming {
            streamingUseCase.startStreaming()
        }

        let url = streamingUseCase.streamingLink(for: node)
        media = url.map { VLCMedia(url: $0) }
    }
}

extension MEGAVLCPlayer: VideoRenderable {
    func setupPlayer(in layer: any PlayerLayerProtocol) {
        player.drawable = layer
    }

    func resizePlayer(to frame: CGRect) {
        // Not needed for VLCMediaPlayer, as it handles resizing automatically
    }
}

extension MEGAVLCPlayer: VLCMediaPlayerDelegate {
    nonisolated func mediaPlayerStateChanged(_ aNotification: Notification) {
        Task { @MainActor in
            state = .init(from: player.state)
        }
    }

    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        Task { @MainActor in
            currentTime = .milliseconds(Double(truncating: player.time.value ?? 0))
            duration = .milliseconds(Double(truncating: media?.length.value ?? 0))
        }
    }
}

extension MEGAVLCPlayer {
    static func liveValue(
        node: any PlayableNode
    ) -> MEGAVLCPlayer {
        let player = MEGAVLCPlayer(streamingUseCase: DependencyInjection.streamingUseCase)
        player.loadNode(node)
        return player
    }

    static var liveValue: MEGAVLCPlayer {
        MEGAVLCPlayer(streamingUseCase: DependencyInjection.streamingUseCase)
    }
}

private extension PlaybackState {
    init(from vlcState: VLCMediaPlayerState) {
        switch vlcState {
        case .stopped:
            self = .stopped
        case .playing:
            self = .playing
        case .paused:
            self = .paused
        case .buffering, .opening, .esAdded:
            self = .buffering
        case .ended:
            self = .ended
        case .error:
            self = .error
        @unknown default:
            self = .error
        }
    }
}
