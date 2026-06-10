import Foundation
import MEGADomain

// MARK: - Protocol

protocol AudioURLResolutionUseCaseProtocol {
    func url(for source: PlaybackSource) -> URL?
}

// MARK: - Implementation

struct AudioURLResolutionUseCase: AudioURLResolutionUseCaseProtocol {
    private let streamingUseCase: any StreamingUseCaseProtocol
    private let folderLinkStreamingUseCase: any StreamingUseCaseProtocol

    init(streamingUseCase: some StreamingUseCaseProtocol, folderLinkStreamingUseCase: some StreamingUseCaseProtocol) {
        self.streamingUseCase = streamingUseCase
        self.folderLinkStreamingUseCase = folderLinkStreamingUseCase
    }

    func url(for source: PlaybackSource) -> URL? {
        switch source {
        case .offlineFiles(let paths, let index):
            return paths.indices.contains(index) ? paths[index] : paths.first

        case .cloudNode(let node, _),
             .chatMessage(let node, _, _),
             .searchResult(let node):
            return streamingURL(for: node, using: streamingUseCase)

        case .folderLink(let node, _):
            return streamingURL(for: node, using: folderLinkStreamingUseCase)

        case .fileLink(_, let node):
            guard let node else {
                assertionFailure("[AudioURLResolutionUseCase] .fileLink source has nil node — caller must resolve the node before calling play(source:)")
                return nil
            }
            return streamingURL(for: node, using: folderLinkStreamingUseCase)
        }
    }

    // MARK: - Private

    private func streamingURL(for node: NodeEntity, using useCase: any StreamingUseCaseProtocol) -> URL? {
        if !useCase.isStreaming { useCase.startStreaming() }
        return useCase.streamingLink(for: NodeEntityAdapter(node))
    }
}

// MARK: - NodeEntityAdapter

/// Bridges `NodeEntity` to `PlayableNode` so `StreamingUseCaseProtocol` can
/// accept domain entities without knowing about SDK types.
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
