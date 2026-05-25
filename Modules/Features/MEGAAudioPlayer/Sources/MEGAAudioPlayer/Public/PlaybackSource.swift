import Foundation
import MEGADomain

/// Where the audio player should pick up content from. Each case carries
/// exactly the data its scenario needs — replaces the legacy
/// `AudioPlayerConfigEntity` parameter bag where mutually exclusive scenarios
/// were encoded as multiple optionals.
public enum PlaybackSource: Sendable {
    case cloudNode(node: NodeEntity, queue: [NodeEntity] = [])
    case chatMessage(node: NodeEntity, chatId: HandleEntity, messageId: HandleEntity)
    case fileLink(url: URL, node: NodeEntity? = nil)
    case folderLink(node: NodeEntity, queue: [NodeEntity] = [])
    case offlineFiles(paths: [URL], startIndex: Int = 0)
    case searchResult(node: NodeEntity)

    var primaryNode: NodeEntity? {
        switch self {
        case .cloudNode(let node, _),
             .chatMessage(let node, _, _),
             .folderLink(let node, _),
             .searchResult(let node):
            return node
        case .fileLink(_, let node):
            return node
        case .offlineFiles:
            return nil
        }
    }
}
