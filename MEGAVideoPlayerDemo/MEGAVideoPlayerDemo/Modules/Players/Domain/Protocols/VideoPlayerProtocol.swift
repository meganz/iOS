import Foundation
import Combine

typealias VideoPlayerProtocol = PlaybackStateObservable
    & PlaybackControllable
    & NodeLoadable
    & VideoRenderable
    & PlaybackDebugMessageObservable
    & PlayerOptionIdentifiable

// MARK: - Protocols

@MainActor
protocol PlaybackStateObservable {
    var state: PlaybackState { get }
    var currentTime: Duration { get }
    var duration: Duration { get }

    var statePublisher: AnyPublisher<PlaybackState, Never> { get }
    var currentTimePublisher: AnyPublisher<Duration, Never> { get }
    var durationPublisher: AnyPublisher<Duration, Never> { get }
}

@MainActor
protocol PlaybackControllable {
    func play()
    func pause()
    func stop()
    func jumpForward(by seconds: TimeInterval)
    func jumpBackward(by seconds: TimeInterval)
    func seek(to time: TimeInterval)
}

@MainActor
protocol VideoRenderable {
    func setupPlayer(in layer: any PlayerLayerProtocol)
    func resizePlayer(to frame: CGRect)
}

@MainActor
protocol NodeLoadable {
    func loadNode(_ node: any PlayableNode)
}

protocol PlaybackDebugMessageObservable {
    var debugMessagePublisher: AnyPublisher<String, Never> { get }
}

protocol PlayerOptionIdentifiable {
    var option: VideoPlayerOption { get }
}
