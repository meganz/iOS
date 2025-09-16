import Foundation
import MEGAPreference
import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing

@MainActor
struct ResumePlaybackPositionUseCaseTests {
    @Test
    func saveAndRetrievePlaybackPosition() {
        let sut = makeSUT()
        let mockNode = MockPlayableNode(id: "test_123", nodeName: "test_video.mp4")

        sut.savePlaybackPosition(120.5, for: mockNode)
        let retrievedPosition = sut.getPlaybackPosition(for: mockNode)

        #expect(retrievedPosition == 120.5)
    }

    @Test
    func savePositionWithDifferentNodes() {
        let sut = makeSUT()
        let mockNode1 = MockPlayableNode(id: "unique_1", nodeName: "video1.mp4")
        let mockNode2 = MockPlayableNode(id: "unique_2", nodeName: "video2.mp4")

        sut.savePlaybackPosition(100.0, for: mockNode1)
        sut.savePlaybackPosition(200.0, for: mockNode2)

        #expect(sut.getPlaybackPosition(for: mockNode1) == 100.0)
        #expect(sut.getPlaybackPosition(for: mockNode2) == 200.0)
    }

    // MARK: - Helper

    private func makeSUT(
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase()
    ) -> ResumePlaybackPositionUseCase {
        ResumePlaybackPositionUseCase(
            preferenceUseCase: preferenceUseCase
        )
    }
}
