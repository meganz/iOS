import Foundation
import MEGADomain

// MARK: - Protocol

/// Builds the address a track's bytes are read from
protocol AudioTrackURLUseCaseProtocol: Sendable {
    func url(for track: PlaybackTrack) -> URL?
}

// MARK: - Implementation

struct AudioTrackURLUseCase: AudioTrackURLUseCaseProtocol {
    private let streamingRepository: any AudioStreamingRepositoryProtocol
    private let localFileURL: @Sendable (any PlayableNode) -> URL?

    init(
        streamingRepository: some AudioStreamingRepositoryProtocol = DependencyInjection.streamingRepository,
        localFileURL: @escaping @Sendable (any PlayableNode) -> URL? = DependencyInjection.localFileURLProvider
    ) {
        self.streamingRepository = streamingRepository
        self.localFileURL = localFileURL
    }

    func url(for track: PlaybackTrack) -> URL? {
        if case .offline(let file) = track { return file }
        if case .offlineNode(_, let file) = track { return file }
        guard let node = track.streamingNode else { return nil }

        // An account node the user already has on the device is read from that copy rather than
        // streamed back from the API: it starts instantly, costs no transfer quota
        if case .account(let accountNode) = node,
           let localFile = localFileURL(accountNode) {
            return localFile
        }

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
        case .offline, .offlineNode:
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
