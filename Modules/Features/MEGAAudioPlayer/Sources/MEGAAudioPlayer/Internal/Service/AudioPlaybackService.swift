import Combine
import Foundation
import MEGADomain
import SwiftUI

/// Single state projection the VM subscribes to.
struct AudioPlaybackState {
    var currentSource: PlaybackSource

    /// Display title for the current track. Starts as the filename / node name
    /// when playback begins, then gets overwritten by the engine once ID3
    /// `commonKeyTitle` is parsed
    var title: String

    /// Display artist for the current track.
    var artist: String?

    /// URL of the current track's cover artwork — typically produced by the
    /// engine after it parses track metadata.
    var artworkURLString: String?

    /// Coarse playback status the mini player binds to.
    var status: PlaybackStatus = .loading

    var currentNode: NodeEntity? { currentSource.primaryNode }
}

enum PlaybackStatus {
    /// Audio is buffering or metadata is still being parsed — the mini player
    /// shows the throbber and the play/pause toggle is inert.
    case loading
    case playing
    case paused
}

/// App-level audio service abstraction.
@MainActor
protocol AudioPlaybackServiceProtocol: AnyObject {
    var statePublisher: AnyPublisher<AudioPlaybackState?, Never> { get }

    func play(source: PlaybackSource)

    /// Flip between play and paused. Inert while loading. Wired to the mini
    /// player's left-icon tap.
    func togglePlayPause()

    /// Stop playback entirely and tear down the session.
    func stop()
}

/// Live implementation of `AudioPlaybackServiceProtocol`. Process-lifetime
/// singleton via `shared`. Currently a stub — engine, audio-session, remote
/// command, now-playing, and stats wiring land in the engine-migration
@MainActor
final class AudioPlaybackService: AudioPlaybackServiceProtocol {
    static let shared = AudioPlaybackService()

    private let stateSubject = CurrentValueSubject<AudioPlaybackState?, Never>(nil)

    var statePublisher: AnyPublisher<AudioPlaybackState?, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private init() {}

    func play(source: PlaybackSource) {
        stateSubject.value = AudioPlaybackState(
            currentSource: source,
            title: Self.displayName(for: source),
            artist: nil
        )
    }

    /// Filename / node-name projection used as the title; fall back to the local file URL's last path
    /// component only for offline playback, where the URL is a `file://` URL
    /// and the last path component IS the filename.
    private static func displayName(for source: PlaybackSource) -> String {
        switch source {
        case .cloudNode(let node, _),
             .chatMessage(let node, _, _),
             .folderLink(let node, _),
             .searchResult(let node):
            return node.name
        case .fileLink(_, let node):
            return node?.name ?? ""
        case .offlineFiles(let paths, let startIndex):
            let url = paths.indices.contains(startIndex) ? paths[startIndex] : paths.first
            return url?.lastPathComponent ?? ""
        }
    }

    func togglePlayPause() {
        // TBD: engine-migration sprint — flip the AVPlayer rate and let the
        // engine's KVO push the resulting `.playing` / `.paused` status back
        // through `stateSubject`. Until then this is intentionally inert so
        // the mini player can still be exercised by previews and mocks.
    }

    func stop() {
        stateSubject.value = nil
    }
}
