import Foundation
import Combine

typealias VideoPlayerProtocol = PlaybackStateObservable & PlaybackControllable & NodeLoadable & VideoRenderable

// MARK: - Protocols

@MainActor
protocol PlaybackStateObservable {
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

// MARK: - Entities

enum PlaybackState {
    case stopped
    case playing
    case paused
    case buffering
    case ended
    case error
}
