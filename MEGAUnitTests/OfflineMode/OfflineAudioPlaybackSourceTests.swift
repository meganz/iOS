@testable import MEGA
import MEGAAppSDKRepoMock
import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

/// The audio player playing local copies while the device is offline (IOS-12412).
@MainActor
@Suite("Offline audio playback source")
struct OfflineAudioPlaybackSourceTests {

    @Test("With the flag off nothing changes, even offline with a local copy")
    func flagOffKeepsTheNodeSource() {
        let source = makeSource(for: MockNode(handle: 1), isNewOfflineModeEnabled: false, localCopies: [1: song1])

        #expect(source == nil)
    }

    @Test("Online nothing changes, so a downloaded file still streams as it did")
    func onlineKeepsTheNodeSource() {
        let source = makeSource(for: MockNode(handle: 1), isConnected: true, localCopies: [1: song1])

        #expect(source == nil)
    }

    /// Refusing to open such a file is `OfflineFileOpenGuard`'s job at the tap site (IOS-12411);
    /// swapping in a source with nothing to read would only hide that.
    @Test("Offline, a node with no local copy keeps the node source")
    func offlineWithoutLocalCopyKeepsTheNodeSource() {
        let source = makeSource(for: MockNode(handle: 1), localCopies: [:])

        #expect(source == nil)
    }

    @Test("Offline, a downloaded node plays its local copy and keeps its node")
    func offlineWithLocalCopyPlaysTheFile() throws {
        let source = try #require(offlineNodes(in: makeSource(for: MockNode(handle: 1), localCopies: [1: song1])))

        #expect(source.node.file == song1)
        #expect(source.node.node.handle == 1, "the node has to travel with the file, or the player loses its title and its actions")
        #expect(source.queue.isEmpty)
    }

    @Test("Offline, the queue keeps only the nodes that have a local copy")
    func offlineQueueDropsWhatCannotBePlayed() throws {
        let nodes = [audioNode(1), audioNode(2), audioNode(3)]

        let source = try #require(offlineNodes(in: makeSource(for: nodes[0], allNodes: nodes, localCopies: [1: song1, 3: song3])))

        #expect(source.node.file == song1)
        #expect(source.queue.map(\.file) == [song1, song3], "the node with no local copy must not reach the queue")
        #expect(source.queue.map(\.node.handle) == [1, 3])
    }

    /// Copies of one file share a fingerprint, and the offline store is addressed by fingerprint,
    /// so every copy resolves to the same path — which is why the track id has to be the handle.
    @Test("Offline, nodes sharing one local copy each keep their place")
    func offlineQueueKeepsNodesSharingOneLocalCopy() throws {
        // Handles 1 and 3 are copies of the same file, so they resolve to the same URL.
        let nodes = [audioNode(1), audioNode(2), audioNode(3)]

        let source = try #require(offlineNodes(in: makeSource(for: nodes[0], allNodes: nodes, localCopies: [1: song1, 2: song2, 3: song1])))

        #expect(source.queue.map(\.node.handle) == [1, 2, 3], "two nodes are two entries online, so they are offline too")
        #expect(source.queue.map(\.file) == [song1, song2, song1])
    }

    /// The whole tap must cost a single read of the offline store, however many siblings there are.
    /// Callers hand over an already-filtered list, so every node here is worth reading.
    @Test("Offline, the whole queue is resolved in one read")
    func offlineQueueIsResolvedInOneLookup() throws {
        let nodes = [audioNode(1), audioNode(2), audioNode(3)]
        var lookedUp: [[HandleEntity]] = []

        _ = try #require(offlineNodes(in: makeSource(
            for: nodes[0],
            allNodes: nodes,
            localCopies: [1: song1, 2: song2, 3: song3],
            onLookup: { lookedUp.append($0) }
        )))

        #expect(lookedUp.count == 1, "one read, not one per node")
        #expect(Set(lookedUp.first ?? []) == [1, 2, 3], "every audio node is resolved by that one read")
    }

    // MARK: - Helpers

    private func audioNode(_ handle: MEGAHandle) -> MockNode {
        MockNode(handle: handle, name: "song\(handle).mp3")
    }

    private var song1: URL { URL(fileURLWithPath: "/offline/song1.mp3") }
    private var song2: URL { URL(fileURLWithPath: "/offline/song2.mp3") }
    private var song3: URL { URL(fileURLWithPath: "/offline/song3.mp3") }

    private func makeSource(
        for node: MEGANode,
        allNodes: [MEGANode] = [],
        isNewOfflineModeEnabled: Bool = true,
        isConnected: Bool = false,
        localCopies: [HandleEntity: URL] = [:],
        onLookup: ([HandleEntity]) -> Void = { _ in }
    ) -> PlaybackSource? {
        MEGANode.makeOfflinePlaybackSource(
            node: node,
            allNodes: allNodes,
            isNewOfflineModeEnabled: isNewOfflineModeEnabled,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: isConnected),
            offlineFileURLs: { nodes in
                onLookup(nodes.map(\.handle))
                return nodes.reduce(into: [MEGANode: URL]()) { result, node in
                    result[node] = localCopies[node.handle]
                }
            }
        )
    }

    /// `PlaybackSource` is not `Equatable`, so the offline case is unwrapped rather than compared.
    private func offlineNodes(in source: PlaybackSource?) -> (node: OfflineNodeFile, queue: [OfflineNodeFile])? {
        guard case .offlineNodes(let node, let queue) = source else { return nil }
        return (node, queue)
    }
}
