import Foundation
import MEGADomain

public enum PlaybackTrack: Sendable {
    case account(NodeEntity)
    case folderLink(NodeEntity)
    case fileLink(url: URL, node: (any PlayableNode)?)
    case offline(URL)
}
