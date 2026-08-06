import Foundation
import MEGADomain

/// Where the audio player should pick up content from. Each case carries
/// exactly the data its scenario needs — replaces the legacy
/// `AudioPlayerConfigEntity` parameter bag where mutually exclusive scenarios
/// were encoded as multiple optionals.
public enum PlaybackSource: Sendable {
    case allAudios(node: NodeEntity, queue: [NodeEntity])
    case chatMessage(node: NodeEntity)
    case cloudNode(node: NodeEntity, queue: [NodeEntity] = [])
    /// a file-link node is a standalone public node that isn't in any tree, so the streaming layer needs the object itself, not a handle.
    case fileLink(url: URL, node: (any PlayableNode)? = nil)
    /// a folder-link node lives in the folder-link SDK instance and has to be authorized before anything
    /// downstream can stream it or act on it, so the caller passes the authorized node objects rather
    /// than handles the account SDK cannot resolve.
    case folderLink(node: any PlayableNode, queue: [any PlayableNode] = [])
    case offlineFiles(file: URL, queue: [URL])
    case recents(node: NodeEntity, queue: [NodeEntity])
    case searchResult(node: NodeEntity)
}
