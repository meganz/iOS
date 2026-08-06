import Foundation
import MEGADomain
import MEGASwift

enum PlaybackQueueBuilder {
    static func build(from source: PlaybackSource) -> PlaybackQueue {
        switch source {
        case .cloudNode(let node, let queue),
             .allAudios(let node, let queue),
             .recents(let node, let queue):
            return nodeQueue(initial: node, queue: queue, name: { $0.name }, wrap: PlaybackTrack.account)

        case .folderLink(let node, let queue):
            return nodeQueue(initial: node, queue: queue, name: { $0.name }, wrap: PlaybackTrack.folderLink)

        case .searchResult(let node),
             .chatMessage(let node):
            return PlaybackQueue(tracks: [.account(node)], currentIndex: 0)

        case .offlineFiles(let file, let queue):
            return offlineQueue(initial: file, queue: queue)

        case .fileLink(let url, let node):
            return PlaybackQueue(tracks: [.fileLink(url: url, node: node)], currentIndex: 0)
        }
    }

    /// Generic over the node type because an account queue carries `NodeEntity` while a folder-link queue
    /// carries the authorized `PlayableNode` objects. Both wrap into tracks whose `id` is the node handle,
    /// which is what the initial track is located by.
    private static func nodeQueue<Node>(
        initial: Node,
        queue: [Node],
        name: (Node) -> String?,
        wrap: (Node) -> PlaybackTrack
    ) -> PlaybackQueue {
        let initialTrack = wrap(initial)
        let tracks = queue.filter { isAudioPlayable(name($0)) }.map(wrap)
        guard !tracks.isEmpty else {
            return PlaybackQueue(tracks: [initialTrack], currentIndex: 0)
        }
        if let index = tracks.firstIndex(where: { $0.id == initialTrack.id }) {
            return PlaybackQueue(tracks: tracks, currentIndex: index)
        }
        return PlaybackQueue(tracks: [initialTrack] + tracks, currentIndex: 0)
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

    private static func isAudioPlayable(_ name: String?) -> Bool {
        name?.fileExtensionGroup.isAudio == true
    }
}
