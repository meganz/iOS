import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import Testing

@MainActor
struct ResumePlaybackPositionUseCaseTests {
    @Test
    func saveAndRetrievePlaybackPosition() {
        let sut = makeSUT()
        let item = VideoPlaybackItem.node(MockPlayableNode(name: "test_video.mp4", fingerprint: "test_123"))

        sut.savePlaybackPosition(120.5, for: item)
        let retrievedPosition = sut.playbackPosition(for: item)

        #expect(retrievedPosition == 120.5)
    }

    @Test
    func savePositionWithDifferentVideos() {
        let sut = makeSUT()
        let item1 = VideoPlaybackItem.node(MockPlayableNode(handle: 1, name: "video1.mp4", fingerprint: "unique_1"))
        let item2 = VideoPlaybackItem.node(MockPlayableNode(handle: 2, name: "video2.mp4", fingerprint: "unique_2"))

        sut.savePlaybackPosition(100.0, for: item1)
        sut.savePlaybackPosition(200.0, for: item2)

        #expect(sut.playbackPosition(for: item1) == 100.0)
        #expect(sut.playbackPosition(for: item2) == 200.0)
    }

    @Test
    func deletePlaybackPosition() {
        let sut = makeSUT()
        let item = VideoPlaybackItem.node(MockPlayableNode(name: "video1.mp4", fingerprint: "unique_1"))
        sut.savePlaybackPosition(100.0, for: item)

        sut.deletePlaybackPosition(for: item)

        #expect(sut.playbackPosition(for: item) == nil)
    }

    @Test
    func offlineFile_shouldResumeWhereTheMatchingNodeLeftOff() {
        let fileURL = URL(fileURLWithPath: "/offline/video1.mp4")
        let sut = makeSUT(fileFingerprintRepository: MockFileFingerprintRepository(fingerprints: [fileURL: "unique_1"]))

        sut.savePlaybackPosition(100.0, for: .node(MockPlayableNode(name: "video1.mp4", fingerprint: "unique_1")))

        #expect(sut.playbackPosition(for: .offlineFile(url: fileURL)) == 100.0)
    }

    @Test
    func node_shouldResumeWhereTheMatchingOfflineFileLeftOff() {
        let fileURL = URL(fileURLWithPath: "/offline/video1.mp4")
        let sut = makeSUT(fileFingerprintRepository: MockFileFingerprintRepository(fingerprints: [fileURL: "unique_1"]))

        sut.savePlaybackPosition(100.0, for: .offlineFile(url: fileURL))

        #expect(sut.playbackPosition(for: .node(MockPlayableNode(name: "video1.mp4", fingerprint: "unique_1"))) == 100.0)
    }

    @Test
    func offlineFile_whenItCannotBeFingerprinted_shouldNotBeRemembered() {
        let fileURL = URL(fileURLWithPath: "/offline/video1.mp4")
        let sut = makeSUT(fileFingerprintRepository: MockFileFingerprintRepository())

        sut.savePlaybackPosition(100.0, for: .offlineFile(url: fileURL))

        #expect(sut.playbackPosition(for: .offlineFile(url: fileURL)) == nil)
    }

    // MARK: - Helper

    private func makeSUT(
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        fileFingerprintRepository: some FileFingerprintRepositoryProtocol = MockFileFingerprintRepository()
    ) -> ResumePlaybackPositionUseCase {
        ResumePlaybackPositionUseCase(
            preferenceUseCase: preferenceUseCase,
            fileFingerprintRepository: fileFingerprintRepository
        )
    }
}
