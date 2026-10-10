import Foundation
import MEGADomain

extension Array where Element == PlaybackTrack {
    /// - Returns: `nil` when none of the tracks is backed by one of the nodes
    func refreshingNodes(_ nodes: [NodeEntity]) -> [PlaybackTrack]? {
        replacingNodes(Dictionary(nodes.map { ($0.handle, $0) }) { _, latest in latest })
    }

    /// - Returns: `nil` when none of the tracks is backed by one of the nodes
    func refreshingFolderLinkNodes(_ nodes: [any PlayableNode]) -> [PlaybackTrack]? {
        replacingFolderLinkNodes(Dictionary(nodes.map { ($0.handle, $0) }) { _, latest in latest })
    }

    /// - Parameter nodes: the node to put in place of each track's node
    /// - Returns: `nil` when none of the tracks is backed by one of the keyed nodes
    func replacingNodes(_ nodes: [HandleEntity: NodeEntity]) -> [PlaybackTrack]? {
        replacing { track in
            guard case .account(let node) = track else { return nil }
            return nodes[node.handle].map(PlaybackTrack.account)
        }
    }

    /// - Parameter nodes: see ``replacingNodes(_:)``
    /// - Returns: `nil` when none of the tracks is backed by one of the keyed nodes
    func replacingFolderLinkNodes(_ nodes: [HandleEntity: any PlayableNode]) -> [PlaybackTrack]? {
        replacing { track in
            guard case .folderLink(let node) = track else { return nil }
            return nodes[node.handle].map(PlaybackTrack.folderLink)
        }
    }

    private func replacing(_ replacement: (PlaybackTrack) -> PlaybackTrack?) -> [PlaybackTrack]? {
        var didReplace = false
        let replaced = map { track in
            guard let newTrack = replacement(track) else { return track }
            didReplace = true
            return newTrack
        }
        return didReplace ? replaced : nil
    }
}
