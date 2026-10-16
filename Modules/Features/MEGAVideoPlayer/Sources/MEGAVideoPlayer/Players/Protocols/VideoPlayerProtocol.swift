import AVFoundation
import AVKit
import Combine
import Foundation
import MEGADomain
import UIKit

public typealias VideoPlayerProtocol = PlaybackStateObservable
    & PlaybackControllable
    & PlaybackItemLoadable
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
    /// The rate playback runs at while playing, kept even while paused.
    var playbackRate: Float { get }
    
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

/// Protocol for video players that can load content from a playback queue.
///
/// This protocol defines the interface for loading video content into a player. It abstracts the
/// process of preparing a video player to play whatever a `VideoPlaybackItem` stands for — a cloud
/// node or a file already on the device.
@MainActor
public protocol PlaybackItemLoadable {
    /// Loads the specified item into the video player, and monitors the queue it belongs to for updates.
    ///
    /// This method prepares the video player to play the item's content. The implementation should
    /// handle the necessary setup for streaming and playback.
    ///
    /// - Parameter item: The video content to be loaded.
    /// - Parameter items: The playback queue the item belongs to, monitored for updates.
    func loadItemAndMonitorUpdate(for item: VideoPlaybackItem, monitor items: [VideoPlaybackItem])

    var currentItem: VideoPlaybackItem? { get set }

    var nodeNamePublisher: AnyPublisher<String, Never> { get }

    var onNodeDeleted: (() -> Void)? { get set }
}

public extension PlaybackItemLoadable {
    /// The cloud node being played, `nil` while playing a file that only exists on the device.
    var currentNode: (any PlayableNode)? { currentItem?.node }

    /// Loads a cloud node, for the callers that only ever deal in nodes.
    func loadNodeAndMonitorUpdate(for node: some PlayableNode, monitor nodes: [some PlayableNode]) {
        loadItemAndMonitorUpdate(for: .node(node), monitor: nodes.map { .node($0) })
    }
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
