import Combine
import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import Testing

/// A file renamed while its queue is playing (IOS-11542).
///
/// The title is derived from two inputs — the track's embedded metadata title and its
/// node name — and the node name is only the fallback. So a rename shows up only where
/// the name is what is being shown. Titles are read off `titlePublisher`, which is what
/// the players and Now Playing subscribe to.
@MainActor
struct AudioPlaybackServiceNodeRenamedTests {

    @Test("Renaming the track that is playing updates its title without restarting it")
    func renamingTheCurrentTrack_updatesTheTitle() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        let titles = TitleRecorder(sut)

        updates.simulateRename(of: [song(1, name: "renamed.mp3")])

        await wait(until: { titles.values.last == "renamed.mp3" })
        #expect(titles.values == ["song1.mp3", "renamed.mp3"])
        #expect(sut.currentQueue.tracks.map(\.displayName) == ["renamed.mp3", "song2.mp3"])
        #expect(sut.currentQueue.current?.id == "1")
        #expect(engine.playedURLs == [streamURL(1)], "nothing was restarted")
    }

    @Test("Renaming an upcoming track updates the queue and leaves the playing title alone")
    func renamingAnUpcomingTrack_updatesTheQueueOnly() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        let titles = TitleRecorder(sut)

        updates.simulateRename(of: [song(2, name: "renamed.mp3")])

        await wait(until: { sut.currentQueue.tracks.last?.displayName == "renamed.mp3" })
        #expect(titles.values == ["song1.mp3"], "the queue changed, the title did not, so nothing is re-sent")
        #expect(engine.playedURLs == [streamURL(1)], "nothing was restarted")
    }

    @Test("A metadata title is not replaced by the new file name")
    func renamingTheCurrentTrack_keepsItsMetadataTitle() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, metadataCache: TitledAudioMetadataCache(titles: ["1": "Tagged Title"]))
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))
        await wait(until: { sut.title == "Tagged Title" })
        let titles = TitleRecorder(sut)

        updates.simulateRename(of: [song(1, name: "renamed.mp3")])

        await wait(until: { sut.currentQueue.current?.displayName == "renamed.mp3" })
        #expect(titles.values == ["Tagged Title"])
    }

    @Test("Turning shuffle off does not bring the old name back")
    func unshufflingKeepsTheNewName() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2), song(3)]))
        sut.toggleShuffle()

        updates.simulateRename(of: [song(2, name: "renamed.mp3")])
        await wait(until: { sut.currentQueue.tracks.contains { $0.displayName == "renamed.mp3" } })
        sut.toggleShuffle()

        #expect(sut.currentQueue.tracks.map(\.displayName) == ["song1.mp3", "renamed.mp3", "song3.mp3"])
    }

    // MARK: - Folder link

    @Test("Renaming the folder-link track that is playing updates its title without restarting it")
    func folderLink_renamingTheCurrentTrack_updatesTheTitle() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1), linkSong(2)]))
        let titles = TitleRecorder(sut)

        updates.simulateFolderLinkRename(of: [linkSong(1, name: "renamed.mp3")])

        await wait(until: { titles.values.last == "renamed.mp3" })
        #expect(titles.values == ["song1.mp3", "renamed.mp3"])
        #expect(sut.currentQueue.tracks.map(\.displayName) == ["renamed.mp3", "song2.mp3"])
        #expect(engine.playedURLs == [streamURL(1)], "nothing was restarted")
    }

    @Test("A folder-link metadata title is not replaced by the new file name")
    func folderLink_renamingTheCurrentTrack_keepsItsMetadataTitle() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, metadataCache: TitledAudioMetadataCache(titles: ["1": "Tagged Title"]))
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1)]))
        await wait(until: { sut.title == "Tagged Title" })
        let titles = TitleRecorder(sut)

        updates.simulateFolderLinkRename(of: [linkSong(1, name: "renamed.mp3")])

        await wait(until: { sut.currentQueue.current?.displayName == "renamed.mp3" })
        #expect(titles.values == ["Tagged Title"])
    }

    /// The two SDKs see trees that are invisible to one another, so neither stream may
    /// be applied to playback out of the other — even on a handle that matches.
    @Test("A folder-link rename leaves Cloud Drive playback alone")
    func account_ignoresFolderLinkRenames() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))
        let titles = TitleRecorder(sut)

        updates.simulateFolderLinkRename(of: [linkSong(1, name: "renamed.mp3")])

        await settle()
        #expect(titles.values == ["song1.mp3"])
        #expect(sut.currentQueue.current?.displayName == "song1.mp3")
    }

    @Test("An account rename leaves folder-link playback alone")
    func folderLink_ignoresAccountRenames() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        sut.play(source: .folderLink(node: linkSong(1), queue: [linkSong(1)]))
        let titles = TitleRecorder(sut)

        updates.simulateRename(of: [song(1, name: "renamed.mp3")])

        await settle()
        #expect(titles.values == ["song1.mp3"])
        #expect(sut.currentQueue.current?.displayName == "song1.mp3")
    }

    // MARK: - Title derivation

    /// The queue moves on a moment before the outgoing metadata title is cleared, so for
    /// that moment the inputs pair the new track's name with the old track's title.
    @Test("Moving to a track with no embedded title shows its name, not the previous track's title")
    func movingToAnUntitledTrack_dropsThePreviousTitle() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, metadataCache: TitledAudioMetadataCache(titles: ["1": "Tagged Title"]))
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        await wait(until: { sut.title == "Tagged Title" })
        let titles = TitleRecorder(sut)

        sut.playNext()

        await wait(until: { titles.values.last == "song2.mp3" })
        #expect(titles.values == ["Tagged Title", "song2.mp3"], "no stale title in between")
        #expect(sut.title == "song2.mp3")
    }

    @Test("Stopping clears the title")
    func stopping_clearsTheTitle() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates, metadataCache: TitledAudioMetadataCache(titles: ["1": "Tagged Title"]))
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))
        await wait(until: { sut.title == "Tagged Title" })
        let titles = TitleRecorder(sut)

        sut.stop()

        #expect(titles.values == ["Tagged Title", ""])
        #expect(sut.title == "")
    }

    // MARK: - Players

    @Test("The full player's playlist shows the new name")
    func renaming_updatesThePlaylist() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        let vm = AudioPlayerViewModel(service: sut)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        await wait(until: { vm.playlistItems.count == 2 })

        updates.simulateRename(of: [song(2, name: "renamed.mp3")])

        await wait(until: { vm.playlistItems.last?.title == "renamed.mp3" })
        #expect(vm.playlistItems.map(\.title) == ["song1.mp3", "renamed.mp3"])
        #expect(vm.playlistItems.map(\.id) == ["1", "2"], "the rows keep their identity")
    }

    @Test("The mini player shows the new name")
    func renaming_updatesTheMiniPlayer() async {
        let engine = MockPlaybackEngine()
        let updates = MockAudioNodeUpdatesUseCase()
        let sut = makeSUT(engine: engine, updates: updates)
        let vm = MiniPlayerViewModel(service: sut)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))
        await wait(until: { vm.title == "song1.mp3" })

        updates.simulateRename(of: [song(1, name: "renamed.mp3")])

        await wait(until: { vm.title == "renamed.mp3" })
        #expect(vm.tracks.map(\.title) == ["renamed.mp3", "song2.mp3"])
    }

    // MARK: - Helpers

    private func song(_ handle: UInt64, name: String? = nil) -> NodeEntity {
        NodeEntity(name: name ?? "song\(handle).mp3", fingerprint: "fingerprint-\(handle)", handle: handle)
    }

    private func linkSong(_ handle: UInt64, name: String? = nil) -> StubPlayableNode {
        StubPlayableNode(handle: handle, name: name ?? "song\(handle).mp3", fingerprint: "fingerprint-\(handle)")
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
        metadataCache: some AudioMetadataCacheProtocol = StubAudioMetadataCache()
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: HandleURLResolver()),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: metadataCache,
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase(),
            audioNodeUpdatesUseCase: updates
        )
    }
}

/// Every value `titlePublisher` sends from the moment it is created, the replayed
/// current one first.
@MainActor
private final class TitleRecorder {
    private(set) var values: [String] = []
    private var cancellable: AnyCancellable?

    init(_ service: AudioPlaybackService) {
        cancellable = service.titlePublisher.sink { [weak self] in self?.values.append($0) }
    }
}

/// Distinct URLs per node, so the engine's log shows which track actually started.
private struct HandleURLResolver: AudioTrackURLUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        switch track {
        case .account(let node):
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

/// Embedded titles by track id; a track left out has none.
private actor TitledAudioMetadataCache: AudioMetadataCacheProtocol {
    let titles: [String: String]

    init(titles: [String: String]) {
        self.titles = titles
    }

    func metadata(for track: PlaybackTrack, throttled: Bool) async -> AudioMetadata? {
        AudioMetadata(title: titles[track.id])
    }

    func cachedMetadata(for track: PlaybackTrack) -> AudioMetadata? { nil }

    func removeAll() {}
}
