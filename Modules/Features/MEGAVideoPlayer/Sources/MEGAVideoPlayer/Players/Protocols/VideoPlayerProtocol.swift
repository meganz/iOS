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
    & ExternalPlaybackObservable
    & AudioTrackSelectable
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
    var isLoopEnabled: Bool { get }
    
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
    /// Rebuilds the current node's player item and resumes from the current playback position, used to
    /// retry after a playback failure where the failed item can no longer be played.
    func replayCurrentNode()
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

@MainActor
public protocol ExternalPlaybackObservable {
    var isExternalPlaybackActive: Bool { get }

    var isExternalPlaybackActivePublisher: AnyPublisher<Bool, Never> { get }
}

public protocol PlayerOptionIdentifiable {
    var option: VideoPlayerOption { get }
}

/// One selectable audio track of the current item.
public struct AudioTrack: Identifiable, Equatable, Sendable {
    /// Index of the matching option within the item's `.audible` media selection group.
    public let id: Int
    /// Already localised by AVFoundation from the track's language, so it needs no translation.
    public let displayName: String

    public init(id: Int, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

/// The alternate audio tracks of the current item, and which one is playing
public struct AudioTrackSelection: Equatable, Sendable {
    public let tracks: [AudioTrack]
    public let selectedIndex: Int

    /// `nil` unless the item carries more than one track and `selectedIndex` points into `tracks`.
    public init?(tracks: [AudioTrack], selectedIndex: Int) {
        guard tracks.count > 1, tracks.indices.contains(selectedIndex) else { return nil }
        self.tracks = tracks
        self.selectedIndex = selectedIndex
    }

    public var selected: AudioTrack { tracks[selectedIndex] }
}

@MainActor
public protocol AudioTrackSelectable {
    /// `nil` unless the current item carries more than one audio track.
    var audioTrackSelectionPublisher: AnyPublisher<AudioTrackSelection?, Never> { get }

    func selectAudioTrack(_ track: AudioTrack)
}
