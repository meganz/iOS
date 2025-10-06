import Foundation
import MEGADomain
import MEGADomainMock
import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing

@MainActor
struct MEGAAVPlayerTests {
    @Test
    func nodeName_whenNodeLoaded_shouldReturnNodeName() async {
        let mockNode = MockPlayableNode(id: "test_456", name: "My Test Video.mp4")
        let sut = makeSUT()

        sut.loadNode(mockNode)

        #expect(sut.nodeName == "My Test Video.mp4")
    }
    
    @Test
    func loadNode_whenHasSavedPosition_shouldResumeFromSavedPosition() async {
        let mockUseCase = MockResumePlaybackPositionUseCase()
        let mockNode = MockPlayableNode(id: "test_123", name: "test_video.mp4")
        let savedPosition: TimeInterval = 120.5
        
        mockUseCase.savePlaybackPosition(savedPosition, for: mockNode)
        
        let sut = makeSUT(resumePlaybackPositionUseCase: mockUseCase)
        
        sut.loadNode(mockNode)
        
        #expect(mockUseCase.getPlaybackPositionCallCount == 1)
    }

    @Test
    func playNext_whenInMiddleOfList_shouldLoadNextNodeAndUpdateCanPlayNext() async {
        let node1 = MockPlayableNode(id: "1", name: "v1.mp4")
        let node2 = MockPlayableNode(id: "2", name: "v2.mp4")
        let node3 = MockPlayableNode(id: "3", name: "v3.mp4")
        let videoNodesUseCase = MockVideoNodesUseCase(
            nodes: [node1, node2, node3]
        )
        let sut = makeSUT(
            videoNodesUseCase: videoNodesUseCase
        )

        sut.loadNode(node2)
        sut.streamVideoNodes(for: node2)
        
        await _ = sut.streamVideoNodesTask?.value

        sut.playNext()

        #expect(sut.nodeName == node3.name)
    }

    @Test
    func playNext_whenAtEnd_shouldDoNothing() async {
        let node1 = MockPlayableNode(id: "1", name: "v1.mp4")
        let node2 = MockPlayableNode(id: "2", name: "v2.mp4")
        let videoNodesUseCase = MockVideoNodesUseCase(
            nodes: [node1, node2]
        )
        let sut = makeSUT(
            videoNodesUseCase: videoNodesUseCase
        )
        sut.loadNode(node2)
        sut.streamVideoNodes(for: node2)

        await _ = sut.streamVideoNodesTask?.value

        sut.playNext()

        #expect(sut.nodeName == node2.name)
    }

    @Test
    func playPrevious_whenInMiddle_shouldLoadPreviousNode() async {
        let node1 = MockPlayableNode(id: "1", name: "v1.mp4")
        let node2 = MockPlayableNode(id: "2", name: "v2.mp4")
        let node3 = MockPlayableNode(id: "3", name: "v3.mp4")
        let videoNodesUseCase = MockVideoNodesUseCase(
            nodes: [node1, node2, node3]
        )
        let sut = makeSUT(
            videoNodesUseCase: videoNodesUseCase
        )

        sut.loadNode(node2)
        sut.streamVideoNodes(for: node2)

        await _ = sut.streamVideoNodesTask?.value

        sut.playPrevious()

        #expect(sut.nodeName == node1.name)
    }

    @Test
    func playPrevious_whenAtStart_shouldStillPlayTheCurrentVideo() async {
        let node1 = MockPlayableNode(id: "1", name: "v1.mp4")
        let node2 = MockPlayableNode(id: "2", name: "v2.mp4")
        let videoNodesUseCase = MockVideoNodesUseCase(
            nodes: [node1, node2]
        )
        let sut = makeSUT(
            videoNodesUseCase: videoNodesUseCase
        )

        sut.loadNode(node1)
        sut.streamVideoNodes(for: node1)
        
        await _ = sut.streamVideoNodesTask?.value

        sut.playPrevious()

        #expect(sut.nodeName == node1.name)
    }

    // MARK: - Helper

    private func makeSUT(
        streamingUseCase: some StreamingUseCaseProtocol = MockStreamingUseCase(),
        resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol = MockResumePlaybackPositionUseCase(),
        videoNodesUseCase: some VideoNodesUseCaseProtocol =
            MockVideoNodesUseCase()
    ) -> MEGAAVPlayer {
        return MEGAAVPlayer(
            streamingUseCase: streamingUseCase,
            notificationCenter: .default,
            resumePlaybackPositionUseCase: resumePlaybackPositionUseCase,
            videoNodesUseCase: videoNodesUseCase
        )
    }
}
