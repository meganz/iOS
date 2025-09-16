import Foundation
import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing

@MainActor
struct MEGAAVPlayerTests {
    @Test
    func nodeName_whenNodeLoaded_shouldReturnNodeName() async {
        let mockNode = MockPlayableNode(id: "test_456", nodeName: "My Test Video.mp4")
        let sut = makeSUT()

        sut.loadNode(mockNode)

        #expect(sut.nodeName == "My Test Video.mp4")
    }
    
    @Test
    func loadNode_whenHasSavedPosition_shouldResumeFromSavedPosition() async {
        let mockUseCase = MockResumePlaybackPositionUseCase()
        let mockNode = MockPlayableNode(id: "test_123", nodeName: "test_video.mp4")
        let savedPosition: TimeInterval = 120.5
        
        mockUseCase.savePlaybackPosition(savedPosition, for: mockNode)
        
        let sut = makeSUT(resumePlaybackPositionUseCase: mockUseCase)
        
        sut.loadNode(mockNode)
        
        #expect(mockUseCase.getPlaybackPositionCallCount == 1)
    }

    // MARK: - Helper

    private func makeSUT(
        resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol = MockResumePlaybackPositionUseCase()
    ) -> MEGAAVPlayer {
        MEGAAVPlayer(
            streamingUseCase: MockStreamingUseCase(),
            notificationCenter: .default,
            resumePlaybackPositionUseCase: resumePlaybackPositionUseCase
        )
    }
}
