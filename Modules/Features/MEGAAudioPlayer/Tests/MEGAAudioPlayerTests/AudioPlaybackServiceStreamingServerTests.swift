import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import MEGASwift
import Testing

/// The streaming server is held before every track, not once per source.
@MainActor
struct AudioPlaybackServiceStreamingServerTests {
    @Test func everyStreamedTrack_holdsTheServer() {
        let server = SpyAudioStreamingRepository()
        let sut = makeSUT(server: server)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1), song(2)]))

        sut.playNext()

        #expect(server.startCallCount == 2)
    }

    /// The SDK hands out no address while the server is down
    @Test func server_isHeldBeforeTheTrackAddressIsResolved() {
        let server = SpyAudioStreamingRepository()
        let urlUseCase = ServerCheckingURLUseCase(server: server)
        let sut = makeSUT(server: server, urlUseCase: urlUseCase)

        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        #expect(urlUseCase.serverStateWhenAsked == [true])
    }

    @Test func offlineFiles_doNotHoldTheServer() {
        let server = SpyAudioStreamingRepository()
        let sut = makeSUT(server: server)
        let file = URL(fileURLWithPath: "/offline/song.mp3")

        sut.play(source: .offlineFiles(file: file, queue: [file]))

        #expect(server.startCallCount == 0)
    }

    @Test func stop_letsGoOfTheServer() {
        let server = SpyAudioStreamingRepository()
        let sut = makeSUT(server: server)
        sut.play(source: .cloudNode(node: song(1), queue: [song(1)]))

        sut.stop()

        #expect(server.isServerRunning == false)
    }

    // MARK: - Helpers

    private func song(_ handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "song\(handle).mp3", handle: handle)
    }

    private func makeSUT(
        server: SpyAudioStreamingRepository,
        urlUseCase: some AudioTrackURLUseCaseProtocol = StreamingURLUseCase()
    ) -> AudioPlaybackService {
        AudioPlaybackService(
            trackResolver: PassthroughTrackResolver(urlUseCase: urlUseCase),
            streamingRepository: server,
            metadataCache: StubAudioMetadataCache(),
            engine: MockPlaybackEngine(),
            notificationCenter: NotificationCenter(),
            playbackContinuationUseCase: StubPlaybackContinuationUseCase()
        )
    }
}

private final class SpyAudioStreamingRepository: AudioStreamingRepositoryProtocol, @unchecked Sendable {
    static var newRepo: SpyAudioStreamingRepository { SpyAudioStreamingRepository() }

    private let isRunningStorage = Atomic<Bool>(wrappedValue: false)
    private let startCallCountStorage = Atomic<Int>(wrappedValue: 0)

    var isServerRunning: Bool { isRunningStorage.wrappedValue }

    var startCallCount: Int { startCallCountStorage.wrappedValue }

    func startServer() {
        startCallCountStorage.mutate { $0 += 1 }
        isRunningStorage.mutate { $0 = true }
    }

    func stopServer() {
        isRunningStorage.mutate { $0 = false }
    }

    func streamingURL(for node: StreamingNode) -> URL? { nil }
}

private struct StreamingURLUseCase: AudioTrackURLUseCaseProtocol {
    func url(for track: PlaybackTrack) -> URL? {
        switch track {
        case .account(let node): URL(string: "http://[::1]:4443/\(node.handle)")
        case .offline(let url): url
        case .folderLink, .fileLink, .offlineNode: nil
        }
    }
}

/// Records whether the server was up each time an address was asked for
private final class ServerCheckingURLUseCase: AudioTrackURLUseCaseProtocol, @unchecked Sendable {
    private let server: SpyAudioStreamingRepository
    private let storage = Atomic<[Bool]>(wrappedValue: [])

    init(server: SpyAudioStreamingRepository) {
        self.server = server
    }

    var serverStateWhenAsked: [Bool] { storage.wrappedValue }

    func url(for track: PlaybackTrack) -> URL? {
        storage.mutate { $0.append(server.isServerRunning) }
        return StreamingURLUseCase().url(for: track)
    }
}
