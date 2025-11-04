import AVFoundation
import AVKit
import Combine
import Foundation
import MEGADomain
import UIKit

public typealias VideoPlayerProtocol = PlaybackStateObservable
    & PlaybackControllable
    & NodeLoadable
    & VideoRenderable
    & PictureInPictureLoadable
    & PlaybackDebugMessageObservable
    & PlayerOptionIdentifiable

// MARK: - Protocols

@MainActor
public protocol PlaybackStateObservable {
    var state: PlaybackState { get }
    var currentTime: Duration { get }
    var duration: Duration { get }
    var canPlayNext: Bool { get }

    var statePublisher: AnyPublisher<PlaybackState, Never> { get }
    var currentTimePublisher: AnyPublisher<Duration, Never> { get }
    var durationPublisher: AnyPublisher<Duration, Never> { get }
    var canPlayNextPublisher: AnyPublisher<Bool, Never> { get }
    var bufferRangePublisher: AnyPublisher<(start: Duration, end: Duration)?, Never> { get }
    var itemStatusPublisher: AnyPublisher<AVPlayerItem.Status, Never> { get }
}

@MainActor
public protocol PlaybackControllable {
    func play()
    func pause()
    func stop()
    func jumpForward(by seconds: TimeInterval)
    func jumpBackward(by seconds: TimeInterval)
    func seek(to time: TimeInterval)
    func seek(to time: TimeInterval) async -> Bool
    func changeRate(to rate: Float)
    func setLooping(_ enabled: Bool)
    func playNext()
    func playPrevious()
}

@MainActor
public protocol VideoRenderable {
    func setupPlayer(in layer: any PlayerViewProtocol)
    func resizePlayer(to frame: CGRect)
    func setScalingMode(_ mode: VideoScalingMode)
    func captureSnapshot() async -> UIImage?
}

@MainActor
public protocol PictureInPictureLoadable {
    func loadPIPController() -> AVPictureInPictureController?
}

/// Protocol for video players that can load content from playable nodes.
///
/// This protocol defines the interface for loading video content into a player.
/// It abstracts the process of preparing a video player to play content from
/// various sources that conform to the `PlayableNode` protocol.
@MainActor
public protocol NodeLoadable {
    /// Loads the specified playable node into the video player. Monitors an array of nodes for updates.
    ///
    /// This method prepares the video player to play content from the specified node.
    /// The implementation should handle the necessary setup for streaming and playback.
    ///
    /// - Parameter node: A playable node containing the video content to be loaded.
    /// - Parameter nodes: An array of playable nodes to monitor for updates.
    func loadNodeAndMonitorUpdate(for node: some PlayableNode, monitor nodes: [some PlayableNode])

    var currentNode: (any PlayableNode)? { get set }

    var nodeNamePublisher: AnyPublisher<String, Never> { get }

    var onNodeDeleted: (() -> Void)? { get set }
}

public protocol PlaybackDebugMessageObservable {
    var debugMessagePublisher: AnyPublisher<String, Never> { get }
}

public protocol PlayerOptionIdentifiable {
    var option: VideoPlayerOption { get }
}
