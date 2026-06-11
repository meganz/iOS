import Foundation
import MEGADomain

// MARK: - Protocol

protocol AudioURLResolutionUseCaseProtocol {
    func url(for source: PlaybackSource) -> URL?
}

// MARK: - Implementation

struct AudioURLResolutionUseCase: AudioURLResolutionUseCaseProtocol {
    private let streamingRepository: any AudioStreamingRepositoryProtocol

    init(streamingRepository: some AudioStreamingRepositoryProtocol) {
        self.streamingRepository = streamingRepository
    }

    func url(for source: PlaybackSource) -> URL? {
        switch source {
        case .offlineFiles(let paths, let index):
            return paths.indices.contains(index) ? paths[index] : paths.first

        case .cloudNode(let node, _),
             .chatMessage(let node, _, _),
             .searchResult(let node):
            return streamingRepository.streamingURL(for: .account(NodeEntityAdapter(node)))

        case .folderLink(let node, _):
            return streamingRepository.streamingURL(for: .folderLink(NodeEntityAdapter(node)))

        case .fileLink(_, let node):
            guard let node else {
                assertionFailure("[AudioURLResolutionUseCase] .fileLink source has nil node — caller must resolve the node before calling play(source:)")
                return nil
            }
            return streamingRepository.streamingURL(for: .fileLink(node))
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
