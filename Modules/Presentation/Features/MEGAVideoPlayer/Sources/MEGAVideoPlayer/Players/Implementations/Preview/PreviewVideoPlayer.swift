import Combine
import Foundation

@MainActor
final class PreviewVideoPlayer: VideoPlayerProtocol {
    @Published var state: PlaybackState
    @Published var currentTime: Duration
    @Published var duration: Duration

    let debugMessage: String
    nonisolated let option: VideoPlayerOption

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        $state.eraseToAnyPublisher()
    }

    var currentTimePublisher: AnyPublisher<Duration, Never> {
        $currentTime.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<Duration, Never> {
        $duration.eraseToAnyPublisher()
    }

    nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        Just(debugMessage).eraseToAnyPublisher()
    }

    init(
        option: VideoPlayerOption = .avPlayer,
        state: PlaybackState = .stopped,
        currentTime: Duration = .seconds(0),
        duration: Duration = .seconds(0),
        debugMessage: String = ""
    ) {
        self.option = option
        self.state = state
        self.currentTime = currentTime
        self.duration = duration
        self.debugMessage = debugMessage
    }

    func play() {}
    func pause() {}
    func stop() {}
    func jumpForward(by seconds: TimeInterval) {}
    func jumpBackward(by seconds: TimeInterval) {}
    func seek(to time: TimeInterval) {}
    func loadNode(_ node: some PlayableNode) {}
    func setupPlayer(in layer: any PlayerLayerProtocol) {}
    func resizePlayer(to frame: CGRect) {}
}
