import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

/// Replacing the nodes behind a queue's tracks (IOS-11543).
///
/// A track's id is its node's handle, so a node already backing a track never takes another
/// track's place: the two would share one id.
struct PlaybackQueueReplacementTests {

    @Test("A track is replaced by a node the queue does not hold")
    func nodeNotInTheQueue_replacesTheTrack() {
        let tracks: [PlaybackTrack] = [.account(song(1)), .account(song(2))]

        let replaced = tracks.replacingNodes([1: song(3)])

        #expect(replaced?.map(\.id) == ["3", "2"])
    }

    @Test("A node already backing a track does not replace another, while the others still do")
    func nodeAlreadyQueued_isNotPutInAnotherTracksPlace() {
        let tracks: [PlaybackTrack] = [.account(song(1)), .account(song(2)), .account(song(3))]

        let replaced = tracks.replacingNodes([1: song(2), 3: song(4)])

        #expect(replaced?.map(\.id) == ["1", "2", "4"])
    }

    @Test("Nothing replaced when the only replacing node is already queued")
    func onlyReplacementAlreadyQueued_replacesNothing() {
        let tracks: [PlaybackTrack] = [.account(song(1)), .account(song(2))]

        #expect(tracks.replacingNodes([1: song(2)]) == nil)
    }

    /// The local copy of a cloud node keeps its handle as its id
    @Test("A node played from its offline copy counts as already queued")
    func nodeQueuedAsOfflineCopy_isNotPutInAnotherTracksPlace() {
        let tracks: [PlaybackTrack] = [
            .account(song(1)),
            .offlineNode(song(2), file: URL(fileURLWithPath: "/offline/song.mp3"))
        ]

        #expect(tracks.replacingNodes([1: song(2)]) == nil)
    }

    /// A rename hands back the node a track already holds
    @Test("A track refreshed with its own node is still refreshed")
    func trackRefreshedWithItsOwnNode_isRefreshed() {
        let tracks: [PlaybackTrack] = [.account(song(1)), .account(song(2))]

        let refreshed = tracks.refreshingNodes([NodeEntity(name: "renamed.mp3", handle: 1)])

        #expect(refreshed?.first?.displayName == "renamed.mp3")
    }

    @Test("A folder-link node already backing a track does not replace another")
    func folderLinkNodeAlreadyQueued_isNotPutInAnotherTracksPlace() {
        let tracks: [PlaybackTrack] = [.folderLink(linkSong(1)), .folderLink(linkSong(2))]

        #expect(tracks.replacingFolderLinkNodes([1: linkSong(2)]) == nil)
    }

    private func song(_ handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "song.mp3", handle: handle)
    }

    private func linkSong(_ handle: HandleEntity) -> StubPlayableNode {
        StubPlayableNode(handle: handle, name: "song.mp3", fingerprint: "fingerprint-\(handle)")
    }
}
