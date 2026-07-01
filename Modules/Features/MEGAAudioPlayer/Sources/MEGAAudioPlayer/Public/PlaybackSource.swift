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
    case folderLink(node: NodeEntity, queue: [NodeEntity] = [])
    case offlineFiles(file: URL, queue: [URL])
    case recents(node: NodeEntity, queue: [NodeEntity])
    case searchResult(node: NodeEntity)
}
