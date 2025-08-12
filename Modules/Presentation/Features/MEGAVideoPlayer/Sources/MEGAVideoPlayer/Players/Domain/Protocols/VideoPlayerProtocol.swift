import Foundation
import Combine

public typealias VideoPlayerProtocol = PlaybackStateObservable
    & PlaybackControllable
    & NodeLoadable
    & VideoRenderable
    & PlaybackDebugMessageObservable
    & PlayerOptionIdentifiable

// MARK: - Protocols

@MainActor
public protocol PlaybackStateObservable {
    var state: PlaybackState { get }
    var currentTime: Duration { get }
    var duration: Duration { get }

    var statePublisher: AnyPublisher<PlaybackState, Never> { get }
    var currentTimePublisher: AnyPublisher<Duration, Never> { get }
    var durationPublisher: AnyPublisher<Duration, Never> { get }
}

@MainActor
public protocol PlaybackControllable {
    func play()
    func pause()
    func stop()
    func jumpForward(by seconds: TimeInterval)
    func jumpBackward(by seconds: TimeInterval)
    func seek(to time: TimeInterval)
}

@MainActor
public protocol VideoRenderable {
    func setupPlayer(in layer: any PlayerLayerProtocol)
    func resizePlayer(to frame: CGRect)
}

@MainActor
public protocol NodeLoadable {
    func loadNode(_ node: any PlayableNode)
}

public protocol PlaybackDebugMessageObservable {
    var debugMessagePublisher: AnyPublisher<String, Never> { get }
}

public protocol PlayerOptionIdentifiable {
    var option: VideoPlayerOption { get }
}
