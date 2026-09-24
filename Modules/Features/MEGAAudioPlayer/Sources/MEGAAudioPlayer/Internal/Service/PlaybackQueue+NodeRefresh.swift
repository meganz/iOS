import Foundation
import MEGADomain

extension Array where Element == PlaybackTrack {
    /// - Returns: `nil` when none of the tracks is backed by one of the nodes
    func refreshingNodes(_ nodes: [NodeEntity]) -> [PlaybackTrack]? {
        let nodesByHandle = Dictionary(nodes.map { ($0.handle, $0) }) { _, latest in latest }
        return replacing { track in
            guard case .account(let node) = track else { return nil }
            return nodesByHandle[node.handle].map(PlaybackTrack.account)
        }
    }

    /// - Returns: `nil` when none of the tracks is backed by one of the nodes
    func refreshingFolderLinkNodes(_ nodes: [any PlayableNode]) -> [PlaybackTrack]? {
        let nodesByHandle = Dictionary(nodes.map { ($0.handle, $0) }) { _, latest in latest }
        return replacing { track in
            guard case .folderLink(let node) = track else { return nil }
            return nodesByHandle[node.handle].map(PlaybackTrack.folderLink)
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
