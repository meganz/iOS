import Foundation
import MEGADomain
import MEGASwift

enum PlaybackQueueBuilder {
    static func build(from source: PlaybackSource) -> PlaybackQueue {
        switch source {
        case .cloudNode(let node, let queue),
             .allAudios(let node, let queue),
             .recents(let node, let queue):
            return nodeQueue(initial: node, queue: queue, wrap: PlaybackTrack.account)

        case .folderLink(let node, let queue):
            return nodeQueue(initial: node, queue: queue, wrap: PlaybackTrack.folderLink)

        case .searchResult(let node),
             .chatMessage(let node):
            return PlaybackQueue(tracks: [.account(node)], currentIndex: 0)

        case .offlineFiles(let file, let queue):
            return offlineQueue(initial: file, queue: queue)

        case .fileLink(let url, let node):
            return PlaybackQueue(tracks: [.fileLink(url: url, node: node)], currentIndex: 0)
        }
    }

    private static func nodeQueue(
        initial: NodeEntity,
        queue: [NodeEntity],
        wrap: (NodeEntity) -> PlaybackTrack
    ) -> PlaybackQueue {
        let queue = queue.filter { isAudioPlayable($0.name) }
        guard !queue.isEmpty else {
            return PlaybackQueue(tracks: [wrap(initial)], currentIndex: 0)
        }
        if let index = queue.firstIndex(where: { $0.handle == initial.handle }) {
            return PlaybackQueue(tracks: queue.map(wrap), currentIndex: index)
        }
        return PlaybackQueue(tracks: [wrap(initial)] + queue.map(wrap), currentIndex: 0)
    }

    private static func offlineQueue(initial: URL, queue: [URL]) -> PlaybackQueue {
        let queue = queue.filter { isAudioPlayable($0.lastPathComponent) }
        guard !queue.isEmpty else {
            return PlaybackQueue(tracks: [.offline(initial)], currentIndex: 0)
        }
        if let index = queue.firstIndex(of: initial) {
            return PlaybackQueue(tracks: queue.map(PlaybackTrack.offline), currentIndex: index)
        }
        return PlaybackQueue(tracks: [.offline(initial)] + queue.map(PlaybackTrack.offline), currentIndex: 0)
    }

    private static func isAudioPlayable(_ name: String) -> Bool {
        name.fileExtensionGroup.isAudio
    }
}
