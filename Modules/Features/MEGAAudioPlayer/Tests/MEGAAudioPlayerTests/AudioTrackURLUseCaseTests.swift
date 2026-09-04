import Foundation
@testable import MEGAAudioPlayer
import MEGADomain
import Testing

struct AudioTrackURLUseCaseTests {

    @Test("A downloaded account node is read from its file on the device, not streamed")
    func downloadedAccountNodeIsReadLocally() {
        let streaming = MockStreamingRepository(streamingURL: streamingURL)
        let sut = makeSUT(streamingRepository: streaming, localFile: localFile)

        #expect(sut.url(for: accountTrack) == localFile)
        #expect(streaming.streamingURLCallCount == 0, "the file is here — nothing to ask the server for")
    }

    @Test("An account node with no copy on the device is streamed")
    func undownloadedAccountNodeIsStreamed() {
        let sut = makeSUT(localFile: nil)

        #expect(sut.url(for: accountTrack) == streamingURL)
    }

    @Test("An offline track is read from its own file")
    func offlineTrackIsReadLocally() {
        let sut = makeSUT(localFile: nil)

        #expect(sut.url(for: .offline(localFile)) == localFile)
    }

    @Test("Only account nodes are looked up on the device — no other track kind can be answered from the offline store")
    func onlyAccountNodesAreLookedUpLocally() {
        let lookup = LocalFileLookupSpy(localFile: localFile)
        let sut = AudioTrackURLUseCase(
            streamingRepository: MockStreamingRepository(streamingURL: streamingURL),
            localFileURL: lookup.provider
        )
        let linkNode = StubPlayableNode(handle: 1)

        // Link nodes live outside the account tree, so the store — keyed by account handles —
        // has nothing to find; an offline track already carries its own file.
        #expect(sut.url(for: .folderLink(linkNode)) == streamingURL)
        #expect(sut.url(for: .fileLink(url: streamingURL, node: linkNode)) == streamingURL)
        _ = sut.url(for: .offline(localFile))

        #expect(lookup.lookupCount == 0)
    }

    @Test("A track with neither a copy on the device nor a streaming link has no URL")
    func trackWithNoSourceHasNoURL() {
        let sut = makeSUT(
            streamingRepository: MockStreamingRepository(streamingURL: nil),
            localFile: nil
        )

        #expect(sut.url(for: accountTrack) == nil)
    }

    // MARK: - Helpers

    private var localFile: URL { URL(fileURLWithPath: "/Offline/track.mp3") }
    private var streamingURL: URL { URL(string: "http://127.0.0.1:4443/track.mp3")! }
    private var accountTrack: PlaybackTrack { .account(NodeEntity(handle: 1)) }

    private func makeSUT(
        streamingRepository: MockStreamingRepository? = nil,
        localFile: URL? = nil
    ) -> AudioTrackURLUseCase {
        AudioTrackURLUseCase(
            streamingRepository: streamingRepository ?? MockStreamingRepository(streamingURL: streamingURL),
            localFileURL: { _ in localFile }
        )
    }
}

// MARK: - Mocks

private final class MockStreamingRepository: AudioStreamingRepositoryProtocol, @unchecked Sendable {
    static var newRepo: MockStreamingRepository { MockStreamingRepository(streamingURL: nil) }

    private(set) var streamingURLCallCount = 0
    private let stubbedURL: URL?

    init(streamingURL: URL?) {
        stubbedURL = streamingURL
    }

    var isServerRunning: Bool { true }
    func startServer() {}
    func stopServer() {}

    func streamingURL(for node: StreamingNode) -> URL? {
        streamingURLCallCount += 1
        return stubbedURL
    }
}

/// Counts lookups, so a test can assert that a track was never even asked about on the device.
private final class LocalFileLookupSpy: @unchecked Sendable {
    private(set) var lookupCount = 0
    private let localFile: URL?

    init(localFile: URL?) {
        self.localFile = localFile
    }

    var provider: @Sendable (any PlayableNode) -> URL? {
        { [self] _ in
            lookupCount += 1
            return localFile
        }
    }
}

private struct StubPlayableNode: PlayableNode {
    let handle: UInt64
    var name: String? = "track.mp3"
    var parentHandle: UInt64 = 0
    var fingerprint: String?
}
