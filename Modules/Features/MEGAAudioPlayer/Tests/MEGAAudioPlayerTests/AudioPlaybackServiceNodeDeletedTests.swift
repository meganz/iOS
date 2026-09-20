import Foundation
import MEGADomain
@testable import MEGAAudioPlayer
import Testing

/// A Cloud Drive file deleted while its queue is playing (IOS-11540).
///
/// The deletion arrives as an SDK node update rather than a playback error: a node
/// in the Rubbish Bin still streams, so nothing fails on its own and the queue has
/// to be reconciled from the update alone.
@MainActor
struct AudioPlaybackServiceNodeDeletedTests {

    @Test("A deleted track that is not playing is dropped, and playback carries on")
    func deletingAnUpcomingTrack_keepsPlaybackRunning() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))

        updates.simulateDeletion(ofNodeHandles: [2])

        await wait(until: { sut.currentQueue.tracks.count == 2 })
        #expect(sut.currentQueue.tracks.map(\.id) == ["1", "3"])
        #expect(sut.currentQueue.current?.id == "1")
        #expect(engine.playedURLs == [streamURL(1)], "nothing was restarted")
    }

    @Test("Deleting the track that is playing skips to the next one and drops it from the queue")
    func deletingTheCurrentTrack_skipsToTheNext() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))
        // Part-way through, so the skip is not just the queue running on to the next
        // track of its own accord.
        engine.simulatePlayhead(at: 5)

        updates.simulateDeletion(ofNodeHandles: [1])

        await wait(until: { sut.currentQueue.current?.id == "2" })
        #expect(sut.currentQueue.tracks.map(\.id) == ["2", "3"])
        #expect(engine.playedURLs == [streamURL(1), streamURL(2)])
    }

    @Test("Deleting the last track in the queue wraps round to the first survivor")
    func deletingTheLastTrack_wrapsAround() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(3), queue: [song(1), song(2), song(3)]))

        updates.simulateDeletion(ofNodeHandles: [3])

        await wait(until: { sut.currentQueue.tracks.count == 2 })
        #expect(sut.currentQueue.current?.id == "1", "playNext wraps, and so does this")
        #expect(sut.currentQueue.tracks.map(\.id) == ["1", "2"])
    }

    @Test("Deleting the only track in the queue ends the session")
    func deletingTheOnlyTrack_stopsPlayback() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        updates.simulateDeletion(ofNodeHandles: [1])

        // A cleared source is what takes the player screen down with it.
        await wait(until: { sut.currentSource == nil })
        #expect(sut.currentQueue.tracks.isEmpty)
        #expect(engine.playedURLs == [streamURL(1)], "nothing else was started")
    }

    /// Deleting a multi-selection reports every node in one update.
    @Test("A batch that takes the current track and others leaves the queue on a survivor")
    func deletingABatch_landsOnASurvivor() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3), song(4)]))

        updates.simulateDeletion(ofNodeHandles: [1, 2, 4])

        await wait(until: { sut.currentQueue.tracks.count == 1 })
        #expect(sut.currentQueue.tracks.map(\.id) == ["3"], "the next survivor, not the next index")
        #expect(sut.currentQueue.current?.id == "3")
        #expect(engine.playedURLs == [streamURL(1), streamURL(3)])
    }

    @Test("A batch that empties the queue ends the session")
    func deletingEveryTrack_stopsPlayback() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))

        updates.simulateDeletion(ofNodeHandles: [1, 2])

        await wait(until: { sut.currentSource == nil })
        #expect(sut.currentQueue.tracks.isEmpty)
    }

    @Test("A node that is not in the queue leaves it alone")
    func deletingAnUnrelatedNode_isANoOp() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))

        updates.simulateDeletion(ofNodeHandles: [9])
        // Batches are delivered in order, so waiting on this one proves the unrelated
        // one was already handled — the assertions below cannot pass by reading too early.
        updates.simulateDeletion(ofNodeHandles: [3])

        await wait(until: { sut.currentQueue.tracks.count == 2 })
        #expect(sut.currentQueue.tracks.map(\.id) == ["1", "2"], "only node 3 went")
        #expect(sut.currentQueue.current?.id == "1")
        #expect(engine.playedURLs == [streamURL(1)], "nothing was restarted")
    }

    /// A node played from its downloaded copy shares the cloud node's handle, but its
    /// bytes come off the device — deleting the cloud file does not stop it.
    @Test("A track playing from its local copy survives the cloud node being deleted")
    func deletingTheCloudNode_leavesTheLocalCopyPlaying() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        let file = URL(fileURLWithPath: "/offline/song1.mp3")
        sut.play(source: .offlineNodes(node: OfflineNodeFile(node: song(1), file: file), queue: []))

        updates.simulateDeletion(ofNodeHandles: [1])

        await settle()
        #expect(sut.currentQueue.tracks.map(\.id) == ["1"])
        #expect(sut.currentSource != nil)
        #expect(engine.playedURLs == [file])
    }

    @Test("Deletions arriving with no session are ignored")
    func deletingWithNothingPlaying_isANoOp() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)

        updates.simulateDeletion(ofNodeHandles: [1])

        await settle()
        #expect(sut.currentSource == nil)
        #expect(engine.playedURLs.isEmpty)
    }

    @Test("Turning shuffle off does not bring a deleted track back")
    func unshufflingDoesNotRestoreADeletedTrack() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))
        sut.toggleShuffle()

        updates.simulateDeletion(ofNodeHandles: [2])
        await wait(until: { sut.currentQueue.tracks.count == 2 })
        sut.toggleShuffle()

        #expect(sut.currentQueue.tracks.map(\.id) == ["1", "3"])
        #expect(sut.currentQueue.current?.id == "1")
    }

    /// Two halves to this: the deleted track's resume point goes, and the `stop()`
    /// that ends the session must not write a fresh one back on its way out — a
    /// track taken away mid-play is not somewhere the listener chose to stop.
    @Test("Emptying the queue clears the deleted track's resume position")
    func deletingTheOnlyTrack_clearsItsResumePosition() async {
        let engine = MockPlaybackEngine()
        // Above the minimum resumable duration, so a position is saved at all.
        engine.itemDuration = 400
        let updates = MockAudioNodeUpdatesUseCase()
        let resumeStore = SpyPlaybackContinuationUseCase()
        let sut = makeSUT(engine: engine, updates: updates, playbackContinuationUseCase: resumeStore)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))
        engine.simulatePlayhead(at: 120)

        updates.simulateDeletion(ofNodeHandles: [1])

        await wait(until: { sut.currentSource == nil })
        #expect(
            resumeStore.operations == [.removed(fingerprint(1))],
            "cleared exactly once, with no save written back by the stop"
        )
    }

    @Test("A batch that empties the queue clears it too")
    func deletingEveryTrack_clearsTheCurrentTracksResumePosition() async {
        let engine = MockPlaybackEngine()
        engine.itemDuration = 400
        let updates = MockAudioNodeUpdatesUseCase()
        let resumeStore = SpyPlaybackContinuationUseCase()
        let sut = makeSUT(engine: engine, updates: updates, playbackContinuationUseCase: resumeStore)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        engine.simulatePlayhead(at: 120)

        updates.simulateDeletion(ofNodeHandles: [1, 2])

        await wait(until: { sut.currentSource == nil })
        #expect(resumeStore.operations == [.removed(fingerprint(1))])
    }

    // MARK: - Helpers

    private func song(_ handle: UInt64) -> NodeEntity {
        NodeEntity(name: "song\(handle).mp3", fingerprint: fingerprint(handle), handle: handle)
    }

    private func fingerprint(_ handle: UInt64) -> String {
        "fingerprint-\(handle)"
    }

    private func streamURL(_ handle: UInt64) -> URL {
        URL(string: "https://stream.test/\(handle)")!
    }

    /// Lets a delivery that should change nothing actually run before the assertions.
    ///
    /// Real time has to pass rather than a count of yields: the batch reaches the
    /// service on its own task, and a yield count only rearranges work already
    /// queued. Used only where the expected outcome is "nothing happened" and there
    /// is therefore nothing to wait *for* — every other test anchors on an
    /// observable change instead.
    private func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        updates: MockAudioNodeUpdatesUseCase,
        playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol = StubPlaybackContinuationUseCase()
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: StreamingNodeURLResolver()),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioNodeUpdatesUseCase: updates
        )
    }
}

/// Distinct URLs per node, so the engine's log shows which track actually started.
private struct StreamingNodeURLResolver: AudioTrackURLUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        switch track {
        case .account(let node):
            return URL(string: "https://stream.test/\(node.handle)")
        case .offlineNode(_, let file):
            return file
        case .offline(let url):
            return url
        case .folderLink, .fileLink:
            return nil
        }
    }
}
