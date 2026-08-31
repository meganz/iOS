import Foundation
import MEGADomain

extension PlaybackTrack {
    var id: String {
        switch self {
        case .account(let node):
            return String(node.handle)
        case .folderLink(let node):
            return String(node.handle)
        case .fileLink(let url, let node):
            return node.map { String($0.handle) } ?? url.path
        case .offline(let url):
            return url.path
        case .offlineNode(let node, _):
            return String(node.handle)
        }
    }

    /// Identity across sources, as opposed to `id`, which identifies a track *within* one queue and
    /// is only the node handle. One node has both a streamed (`.account`) and a local (`.offlineNode`)
    /// form sharing that handle, so comparing ids alone makes swapping one for the other look like a
    /// repeat tap on what is already playing
    var playbackIdentity: String {
        switch self {
        case .account:
            return "account:\(id)"
        case .folderLink:
            return "folderLink:\(id)"
        case .fileLink:
            return "fileLink:\(id)"
        case .offline:
            return "offline:\(id)"
        case .offlineNode:
            return "offlineNode:\(id)"
        }
    }

    var displayName: String {
        switch self {
        case .account(let node):
            return node.name
        case .folderLink(let node):
            return node.name ?? ""
        case .fileLink(let url, let node):
            return node?.name ?? url.lastPathComponent
        case .offline(let url):
            return url.lastPathComponent
        case .offlineNode(let node, _):
            return node.name
        }
    }
}

extension PlaybackSource {
    var initialTrack: PlaybackTrack {
        switch self {
        case .cloudNode(let node, _),
             .allAudios(let node, _),
             .recents(let node, _),
             .searchResult(let node),
             .chatMessage(let node):
            return .account(node)
        case .folderLink(let node, _):
            return .folderLink(node)
        case .offlineFiles(let file, _):
            return .offline(file)
        case .offlineNodes(let node, _):
            return .offlineNode(node.node, file: node.file)
        case .fileLink(let url, let node):
            return .fileLink(url: url, node: node)
        }
    }
}

struct PlaybackQueue: Sendable {
    let tracks: [PlaybackTrack]
    let currentIndex: Int

    static let empty = PlaybackQueue(tracks: [], currentIndex: 0)

    var current: PlaybackTrack? {
        tracks.indices.contains(currentIndex) ? tracks[currentIndex] : nil
    }
    
    func moving(from source: Int, toOffset destination: Int) -> PlaybackQueue {
        guard tracks.indices.contains(source),
              (0...tracks.count).contains(destination) else { return self }

        let currentID = current?.id
        var reordered = tracks
        let track = reordered.remove(at: source)
        reordered.insert(track, at: destination > source ? destination - 1 : destination)

        let newIndex = currentID
            .flatMap { id in reordered.firstIndex { $0.id == id } }
            ?? currentIndex
        return PlaybackQueue(tracks: reordered, currentIndex: newIndex)
    }
}
