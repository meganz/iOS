import Foundation
import MEGADomain

// MARK: - Protocol

/// Builds the address a track's bytes are read from.
///
/// Synchronous and pure: no network, no authorization check. For node-backed
/// tracks this is a local HTTP-server link, which is built the same way whether
/// or not the node is still available — a blocked node yields a URL whose reads
/// simply fail. Playback admission is a separate concern, see
/// ``AudioTrackResolutionUseCaseProtocol``.
protocol AudioTrackURLUseCaseProtocol: Sendable {
    func url(for track: PlaybackTrack) -> URL?
}

// MARK: - Implementation

struct AudioTrackURLUseCase: AudioTrackURLUseCaseProtocol {
    private let streamingRepository: any AudioStreamingRepositoryProtocol

    init(streamingRepository: some AudioStreamingRepositoryProtocol = DependencyInjection.streamingRepository) {
        self.streamingRepository = streamingRepository
    }

    func url(for track: PlaybackTrack) -> URL? {
        if case .offline(let file) = track { return file }
        guard let node = track.streamingNode else { return nil }
        return streamingRepository.streamingURL(for: node)
    }
}

// MARK: - StreamingNode mapping

extension PlaybackTrack {
    /// The track as the SDK-facing repositories want it — tagged with the tree it
    /// must be resolved and authorized against. `nil` for offline files, which
    /// have no node behind them.
    var streamingNode: StreamingNode? {
        switch self {
        case .offline:
            return nil
        case .account(let node):
            return .account(NodeEntityAdapter(node))
        case .folderLink(let node):
            return .folderLink(node)
        case .fileLink(_, let node):
            guard let node else {
                assertionFailure("[AudioTrackURLUseCase] .fileLink track has nil node — caller must resolve the node before enqueuing it")
                return nil
            }
            return .fileLink(node)
        }
    }
}

// MARK: - NodeEntityAdapter

private struct NodeEntityAdapter: PlayableNode {
    let handle: UInt64
    let name: String?
    let parentHandle: UInt64
    let fingerprint: String?

    init(_ entity: NodeEntity) {
        handle = entity.handle
        name = entity.name
        parentHandle = entity.parentHandle
        fingerprint = entity.fingerprint
    }
}
