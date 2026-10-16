import Foundation

/// What the player was handed to play, and where its bytes are read from.
///
/// A cloud node is streamed from the API — or read from its local copy when the user has already
/// downloaded it. An offline file has no cloud node behind it at all: there is nothing to stream, no
/// updates to monitor and no handle to be found by, so its path is all it carries and all it needs.
public enum VideoPlaybackItem: Sendable {
    case node(any PlayableNode)
    case offlineFile(url: URL)
}

public extension VideoPlaybackItem {
    /// The cloud node being played, `nil` for a file that only exists on the device. Actions that
    /// need something in the cloud to act on — the more menu, rubbish bin checks — hang off this.
    var node: (any PlayableNode)? {
        switch self {
        case .node(let node): node
        case .offlineFile: nil
        }
    }

    var name: String {
        switch self {
        case .node(let node): node.name ?? ""
        case .offlineFile(let url): url.lastPathComponent
        }
    }

    /// Identity within a playback queue: cloud nodes are unique by handle, offline files by path.
    var playbackID: String {
        switch self {
        case .node(let node): String(node.handle)
        case .offlineFile(let url): url.path
        }
    }

    /// The file on the device this item is played from, when it is one. A cloud node's local copy is
    /// not known here: it is looked up by whoever resolves the item's URL.
    var offlineFileURL: URL? {
        switch self {
        case .node: nil
        case .offlineFile(let url): url
        }
    }
}
