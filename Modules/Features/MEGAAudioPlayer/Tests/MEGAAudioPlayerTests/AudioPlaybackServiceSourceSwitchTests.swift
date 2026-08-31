import Foundation
import MEGADomain
@testable import MEGAAudioPlayer
import Testing

/// `play(source:)` ignores a source that is already playing. A node's streamed and local forms
/// share one handle, so that check has to look past the track id (IOS-12412).
@MainActor
struct AudioPlaybackServiceSourceSwitchTests {

    /// What the user does when the connection drops mid-track: tap the same file again, expecting
    /// the downloaded copy. Both sources carry handle 1, so an id-only check would drop this tap
    /// and leave the player on the streaming URL that can no longer be read.
    @Test func playingTheSameNodeFromItsLocalCopy_switchesToTheFile() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: .cloudNode(node: song, queue: [song]))
        #expect(engine.playedURLs == [streamURL])

        sut.play(source: .offlineNodes(node: OfflineNodeFile(node: song, file: localURL), queue: []))

        #expect(engine.playedURLs == [streamURL, localURL], "the local copy has to replace the streaming URL")
    }

    /// The mirror case, so the fix is not one-directional: back online, the same tap streams again.
    @Test func playingTheSameNodeFromTheCloudAgain_switchesBackToStreaming() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: .offlineNodes(node: OfflineNodeFile(node: song, file: localURL), queue: []))

        sut.play(source: .cloudNode(node: song, queue: [song]))

        #expect(engine.playedURLs == [localURL, streamURL])
    }

    @Test func playingTheSameSourceTwice_isStillIgnored() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        sut.play(source: .cloudNode(node: song, queue: [song]))

        sut.play(source: .cloudNode(node: song, queue: [song]))

        #expect(engine.playedURLs == [streamURL], "a repeat tap must not restart the track")
    }

    @Test func playingTheSameLocalCopyTwice_isStillIgnored() {
        let engine = MockPlaybackEngine()
        let sut = makeSUT(engine: engine)
        let source = PlaybackSource.offlineNodes(node: OfflineNodeFile(node: song, file: localURL), queue: [])
        sut.play(source: source)

        sut.play(source: source)

        #expect(engine.playedURLs == [localURL])
    }

    // MARK: - Helpers

    private var song: NodeEntity { NodeEntity(name: "song.mp3", handle: 1) }
    private var streamURL: URL { URL(string: "https://stream.test/1")! }
    private var localURL: URL { URL(fileURLWithPath: "/offline/song.mp3") }

    private func makeSUT(engine: MockPlaybackEngine) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: NodeURLResolver()),
            streamingRepository: StubAudioStreamingRepository(),
            metadataCache: StubAudioMetadataCache(),
            engine: engine,
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}

/// Gives a streamed node and its local copy distinct URLs, which is what lets the engine show
/// whether the swap happened.
private struct NodeURLResolver: AudioTrackURLUseCaseProtocol {
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
