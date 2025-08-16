@preconcurrency import Combine
import MEGAVideoPlayer
import MobileVLCKit

@MainActor
final class MEGAVLCPlayer: NSObject {
    private let player = VLCMediaPlayer()
    private var media: VLCMedia? {
        didSet { player.media = media }
    }

    private let stateSubject: CurrentValueSubject<PlaybackState, Never> = .init(.opening)
    private let currentTimeSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))
    private let durationSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))

    let statePublisher: AnyPublisher<PlaybackState, Never>
    let currentTimePublisher: AnyPublisher<Duration, Never>
    let durationPublisher: AnyPublisher<Duration, Never>

    private nonisolated let debugMessageSubject = PassthroughSubject<String, Never>()

    private let streamingUseCase: any StreamingUseCaseProtocol

    init(streamingUseCase: some StreamingUseCaseProtocol) {
        self.streamingUseCase = streamingUseCase
        self.statePublisher = stateSubject.eraseToAnyPublisher()
        self.currentTimePublisher = currentTimeSubject.eraseToAnyPublisher()
        self.durationPublisher = durationSubject.eraseToAnyPublisher()
        super.init()

        player.delegate = self
    }
}

extension MEGAVLCPlayer: PlayerOptionIdentifiable {
    nonisolated var option: VideoPlayerOption { .vlc }
}

extension MEGAVLCPlayer: PlaybackStateObservable {
    var state: PlaybackState {
        get { stateSubject.value }
        set { stateSubject.send(newValue) }
    }

    var currentTime: Duration {
        get { currentTimeSubject.value }
        set { currentTimeSubject.send(newValue) }
    }

    var duration: Duration {
        get { durationSubject.value }
        set { durationSubject.send(newValue) }
    }
}

extension MEGAVLCPlayer: PlaybackDebugMessageObservable {
    nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        debugMessageSubject.eraseToAnyPublisher()
    }

    func playbackDebugMessage(_ message: String) {
        debugMessageSubject.send(message)
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
    func loadNode(_ node: some PlayableNode) {
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
        Task { @MainActor in stateDidChange() }
    }

    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        Task { @MainActor in timeChanged() }
    }

    private func stateDidChange() {
        state = .init(from: player.state)
    }

    private func timeChanged() {
        updateCurrentTime(milliseconds: player.time.value)
        updateDuration(milliseconds: media?.length.value)
    }

    private func updateCurrentTime(milliseconds time: NSNumber?) {
        guard let time, !(time.doubleValue.isNaN || time.doubleValue.isInfinite) else {
            playbackDebugMessage("Invalid time \(String(describing: time))")
            return
        }

        currentTime = .milliseconds(time.doubleValue)
    }

    private func updateDuration(milliseconds duration: NSNumber?) {
        guard let duration, !(duration.doubleValue.isNaN || duration.doubleValue.isInfinite) else {
            playbackDebugMessage("Invalid duration \(String(describing: time))")
            return
        }

        self.duration = .milliseconds(duration.doubleValue)
    }
}

extension MEGAVLCPlayer {
    static func liveValue(
        node: any PlayableNode
    ) -> MEGAVLCPlayer {
        let player = MEGAVLCPlayer.liveValue
        player.loadNode(node)
        return player
    }

    static var liveValue: MEGAVLCPlayer {
        MEGAVLCPlayer(streamingUseCase: MEGAVideoPlayer.DependencyInjection.streamingUseCase)
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
        case .opening, .esAdded:
            self = .opening
        case .buffering:
            self = .buffering
        case .ended:
            self = .ended
        case .error:
            self = .error("VLCMediaPlayerState.error")
        @unknown default:
            self = .error("Unknown VLCMediaPlayerState: \(vlcState)")
        }
    }
}
