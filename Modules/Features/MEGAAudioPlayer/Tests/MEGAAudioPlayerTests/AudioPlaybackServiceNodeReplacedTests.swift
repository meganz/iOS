import Combine
import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

/// A file replaced while its queue is playing (IOS-11543): by a new version uploaded over it,
/// or by a file of its name another client put in its folder before deleting it.
///
/// The new file is a new node, so the track is re-pointed at it. The one playing restarts
/// from the new file; any other just takes the new node, and the queue carries on.
@MainActor
struct AudioPlaybackServiceNodeReplacedTests {

    @Test("Replacing the track that is playing restarts it from the new file, in the same place in the queue")
    func replacingTheCurrentTrack_restartsFromTheNewFile() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))

        updates.simulateRemoval([1: song(3)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.playedURLs == [streamURL(1), streamURL(3)])
        #expect(sut.currentQueue.tracks.map(\.id) == ["3", "2"])
        #expect(sut.currentQueue.current?.id == "3")
    }

    @Test("Replacing the track while it is paused loads the new file paused, at its start")
    func replacingThePausedTrack_loadsTheNewFilePaused() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        sut.togglePlayPause()
        await wait(until: { sut.status == .paused })

        updates.simulateRemoval([1: song(3)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.loadedPausedURLs == [streamURL(3)], "no sound until the listener asks for it")
        #expect(sut.status == .paused)
        #expect(sut.currentQueue.current?.id == "3")
    }

    /// The first new file cannot be played, so nothing is loaded to tell that the listener
    /// had paused — the next replacement has to remember it.
    @Test("Replacing a paused track again, before its new file could be loaded, keeps it paused")
    func replacingThePausedTrackTwice_staysPaused() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, unresolvableHandles: [3])
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        sut.togglePlayPause()
        await wait(until: { sut.status == .paused })
        updates.simulateRemoval([1: song(3)])
        await wait(until: { sut.status == .error(.urlUnresolved) })

        updates.simulateRemoval([3: song(4)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.loadedPausedURLs == [streamURL(4)], "no sound until the listener asks for it")
        #expect(sut.status == .paused)
    }

    /// The play is asked for while nothing is loaded, so only the engine's intent remembers it.
    @Test("A play asked for between two replacements of a paused track starts the second new file")
    func playAskedForBetweenTwoReplacements_startsTheNewFile() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, unresolvableHandles: [3])
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        sut.togglePlayPause()
        await wait(until: { sut.status == .paused })
        updates.simulateRemoval([1: song(3)])
        await wait(until: { sut.status == .error(.urlUnresolved) })
        sut.togglePlayPause()

        updates.simulateRemoval([3: song(4)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.loadedPausedURLs.isEmpty)
        #expect(sut.status == .playing)
    }

    /// A system pause reads as paused, yet the listener never asked for it — the new file
    /// has to be meant to play, or the interruption ending would leave it silent.
    @Test("Replacing the track during an interruption keeps it meant to play")
    func replacingTheTrackDuringAnInterruption_keepsItIntendedToPlay() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        await wait(until: { sut.status == .playing })
        engine.simulateInterruption()
        await wait(until: { sut.status == .paused })

        updates.simulateRemoval([1: song(3)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.loadedPausedURLs.isEmpty)
        #expect(engine.isPlaybackIntended)
    }

    @Test("Replacing the track while it is playing starts the new file playing")
    func replacingThePlayingTrack_startsTheNewFilePlaying() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        await wait(until: { sut.status == .playing })

        updates.simulateRemoval([1: song(3)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.loadedPausedURLs.isEmpty)
        #expect(sut.status == .playing)
    }

    /// The offer is to resume the old file where it was left, which means nothing for the new one.
    @Test("Replacing the track takes down the offer to resume it")
    func replacingTheCurrentTrack_dismissesTheResumePrompt() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, playbackContinuationUseCase: ResumeOfferingPlaybackContinuationUseCase())
        var prompt: ResumePrompt?
        let cancellable = sut.resumePromptPublisher.sink { prompt = $0 }
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        await wait(until: { prompt != nil })

        updates.simulateRemoval([1: song(3)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(prompt == nil)
        cancellable.cancel()
    }

    @Test("Replacing an upcoming track takes the new file without interrupting playback")
    func replacingAnUpcomingTrack_keepsPlaybackRunning() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))

        updates.simulateRemoval([2: song(3)])

        await wait(until: { sut.currentQueue.tracks.map(\.id) == ["1", "3"] })
        #expect(sut.currentQueue.current?.id == "1")
        #expect(engine.playedURLs == [streamURL(1)], "nothing was restarted")
    }

    @Test("After a replaced track, the queue carries on as before")
    func afterTheReplacedTrack_theQueueCarriesOn() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        updates.simulateRemoval([1: song(3)])
        await wait(until: { engine.playedURLs.count == 2 })

        sut.playNext()

        #expect(engine.playedURLs == [streamURL(1), streamURL(3), streamURL(2)])
    }

    @Test("Turning shuffle off keeps the new file")
    func unshufflingKeepsTheNewFile() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))
        sut.toggleShuffle()

        updates.simulateRemoval([2: song(4)])
        await wait(until: { sut.currentQueue.tracks.contains { $0.id == "4" } })
        sut.toggleShuffle()

        #expect(sut.currentQueue.tracks.map(\.id) == ["1", "4", "3"])
    }

    @Test("A replacement of a file not in the queue changes nothing")
    func replacingAnUnrelatedFile_isANoOp() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))

        updates.simulateRemoval([9: song(3)])
        // Updates are delivered in order, so once this one is handled the unrelated one was too
        updates.simulateRemoval([2: song(4)])

        await wait(until: { sut.currentQueue.tracks.map(\.id) == ["1", "4"] })
        #expect(engine.playedURLs == [streamURL(1)])
    }

    // MARK: - Replacement and deletion together

    @Test("One removal can replace one track and delete another")
    func removalReplacesOneTrackAndDeletesAnother() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))

        updates.simulateRemoval([1: song(4), 3: nil])

        await wait(until: { sut.currentQueue.tracks.map(\.id) == ["4", "2"] })
        #expect(sut.currentQueue.current?.id == "4")
        #expect(engine.playedURLs == [streamURL(1), streamURL(4)])
    }

    /// Re-pointing would leave two tracks with one id
    @Test("A replacing file already in the queue leaves the removed track to be dropped")
    func replacingFileAlreadyQueued_dropsTheRemovedTrack() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))

        updates.simulateRemoval([1: song(2)])

        await wait(until: { sut.currentQueue.current?.id == "2" })
        #expect(sut.currentQueue.tracks.map(\.id) == ["2", "3"])
        #expect(engine.playedURLs == [streamURL(1), streamURL(2)])
    }

    // MARK: - The folder a queued file was in

    @Test("The queued Cloud Drive files are told, each with the folder it was in")
    func queuedFolders_areTheQueuedTracksFolders() async {
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: MockPlaybackEngine(), updates: updates)
        sut.play(source: .cloudNode(node: song(1, in: 10), queue: [song(1, in: 10), song(2, in: 20)]))

        await wait(until: { updates.queuedFolders == [1: 10, 2: 20] })
    }

    @Test("No file counts as queued once playback has stopped")
    func queuedFolders_areEmptyAfterStop() async {
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: MockPlaybackEngine(), updates: updates)
        sut.play(source: .cloudNode(node: song(1, in: 10), queue: [song(1, in: 10)]))
        await wait(until: { updates.queuedFolders == [1: 10] })

        sut.stop()

        #expect(updates.queuedFolders == [:])
    }

    // MARK: - Folder link

    @Test("Replacing the folder-link track that is playing restarts it from the new file")
    func folderLink_replacingTheCurrentTrack_restartsFromTheNewFile() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1), linkSong(2)]))

        updates.simulateFolderLinkRemoval([1: linkSong(3)])

        await wait(until: { engine.playedURLs.count == 2 })
        #expect(engine.playedURLs == [streamURL(1), streamURL(3)])
        #expect(sut.currentQueue.tracks.map(\.id) == ["3", "2"], "replaced, not dropped")
    }

    @Test("A folder-link track whose replacing file can no longer be found is dropped like a deleted one")
    func folderLink_unresolvableReplacement_dropsTheTrack() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1), linkSong(2)]))

        updates.simulateFolderLinkRemoval([1: nil])

        await wait(until: { sut.currentQueue.current?.id == "2" })
        #expect(sut.currentQueue.tracks.map(\.id) == ["2"])
        #expect(engine.playedURLs == [streamURL(1), streamURL(2)])
    }

    /// Re-pointing would leave two tracks with one id
    @Test("A folder-link track whose replacing file is already in the queue is dropped")
    func folderLink_replacingFileAlreadyQueued_dropsTheRemovedTrack() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1), linkSong(2)]))

        updates.simulateFolderLinkRemoval([1: linkSong(2)])

        await wait(until: { sut.currentQueue.current?.id == "2" })
        #expect(sut.currentQueue.tracks.map(\.id) == ["2"])
        #expect(engine.playedURLs == [streamURL(1), streamURL(2)])
    }

    @Test("One folder-link update can replace one track and delete another")
    func folderLink_replacementAndDeletionTogether() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1), linkSong(2), linkSong(3)]))

        updates.simulateFolderLinkRemoval([1: linkSong(4), 3: nil])

        await wait(until: { sut.currentQueue.tracks.map(\.id) == ["4", "2"] })
        #expect(sut.currentQueue.current?.id == "4")
        #expect(engine.playedURLs == [streamURL(1), streamURL(4)])
    }

    /// The deletion skips onto the next track, which by then is already the new file
    @Test("Deleting the folder-link track that is playing while replacing the next one loads only the new file")
    func folderLink_deletingTheCurrentTrackWhileReplacingTheNext_loadsTheNewFileOnce() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1), linkSong(2), linkSong(3)]))

        updates.simulateFolderLinkRemoval([1: nil, 2: linkSong(4)])

        await wait(until: { sut.currentQueue.current?.id == "4" })
        #expect(sut.currentQueue.tracks.map(\.id) == ["4", "3"])
        #expect(engine.playedURLs == [streamURL(1), streamURL(4)], "the old next track is never loaded")
    }

    /// The two SDKs see trees that are invisible to one another, so neither stream may
    /// be applied to playback out of the other — even on a handle that matches.
    @Test("A Cloud Drive replacement leaves folder-link playback alone")
    func folderLink_ignoresAccountReplacements() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1)]))

        updates.simulateRemoval([1: song(3)])

        await settle()
        #expect(sut.currentQueue.tracks.map(\.id) == ["1"])
        #expect(engine.playedURLs == [streamURL(1)])
    }

    @Test("A folder-link replacement leaves Cloud Drive playback alone")
    func account_ignoresFolderLinkReplacements() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        updates.simulateFolderLinkRemoval([1: linkSong(3)])

        await settle()
        #expect(sut.currentQueue.tracks.map(\.id) == ["1"])
        #expect(engine.playedURLs == [streamURL(1)])
    }

    // MARK: - Helpers

    private func song(_ handle: UInt64) -> NodeEntity {
        NodeEntity(name: "song.mp3", fingerprint: "fingerprint-\(handle)", handle: handle)
    }

    private func song(_ handle: UInt64, in folder: HandleEntity) -> NodeEntity {
        NodeEntity(name: "song.mp3", fingerprint: "fingerprint-\(handle)", handle: handle, parentHandle: folder)
    }

    private func linkSong(_ handle: UInt64) -> StubPlayableNode {
        StubPlayableNode(handle: handle, name: "song.mp3", fingerprint: "fingerprint-\(handle)")
    }

    private func streamURL(_ handle: UInt64) -> URL {
        URL(string: "https://stream.test/\(handle)")!
    }

    /// Lets a delivery that should change nothing actually run before the assertions.
    ///
    /// Real time has to pass rather than a count of yields: the batch reaches the
    /// service on its own task. Used only where the expected outcome is "nothing
    /// happened" and there is therefore nothing to wait *for*.
    private func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
    }

    private func makeSUT(
        engine: MockPlaybackEngine,
        updates: MockAudioNodeUpdatesUseCase,
        unresolvableHandles: Set<HandleEntity> = [],
        playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol = StubPlaybackContinuationUseCase()
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: HandleURLResolver(unresolvableHandles: unresolvableHandles)),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: playbackContinuationUseCase,
            audioNodeUpdatesUseCase: updates
        )
    }
}

/// Distinct URLs per node, so the engine's log shows which file actually started.
private struct HandleURLResolver: AudioTrackURLUseCaseProtocol {
    var unresolvableHandles: Set<HandleEntity> = []

    func url(for track: PlaybackTrack) -> URL? {
        switch track {
        case .account(let node):
            guard !unresolvableHandles.contains(node.handle) else { return nil }
            return URL(string: "https://stream.test/\(node.handle)")
        case .folderLink(let node):
            return URL(string: "https://stream.test/\(node.handle)")
        case .offlineNode(_, let file), .offline(let file):
            return file
        case .fileLink:
            return nil
        }
    }
}

/// Offers to resume every track part-way through.
private struct ResumeOfferingPlaybackContinuationUseCase: PlaybackContinuationUseCaseProtocol {
    func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        .displayDialog(playbackTime: 30)
    }

    func savedPlaybackTime(for fingerprint: FingerprintEntity) -> TimeInterval? { 30 }

    func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {}

    @discardableResult
    func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) -> PlaybackContinuationOutcomeEntity { .removed }

    func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {}
}
