import Foundation
import MEGADomain

public enum PlaybackTrack: Sendable {
    case account(NodeEntity)
    case folderLink(any PlayableNode)
    case fileLink(url: URL, node: (any PlayableNode)?)
    case offline(URL)
    /// A cloud node whose bytes are read from its local copy
    case offlineNode(NodeEntity, file: URL)
}
