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
        let mockNode = MockPlayableNode(name: "My Test Video.mp4")
        let sut = makeSUT()

        sut.loadNodeAndMonitorUpdate(for: mockNode, monitor: [MockPlayableNode]())

        #expect(sut.nodeName == "My Test Video.mp4")
    }
    
    @Test
    func loadNode_whenHasSavedPosition_shouldResumeFromSavedPosition() async {
        let mockUseCase = MockResumePlaybackPositionUseCase()
        let mockNode = MockPlayableNode(name: "test_video.mp4", fingerprint: "fingerprint123")
        let savedPosition: TimeInterval = 120.5
        
        mockUseCase.savePlaybackPosition(savedPosition, for: mockNode)
        
        let sut = makeSUT(resumePlaybackPositionUseCase: mockUseCase)
        
        sut.loadNodeAndMonitorUpdate(for: mockNode, monitor: [MockPlayableNode]())

        #expect(mockUseCase.getPlaybackPositionCallCount == 1)
    }

    @Test
    func playNext_whenInMiddleOfList_shouldLoadNextNodeAndUpdateCanPlayNext() async {
        let node1 = MockPlayableNode(handle: 1, name: "v1.mp4")
        let node2 = MockPlayableNode(handle: 2, name: "v2.mp4")
        let node3 = MockPlayableNode(handle: 3, name: "v3.mp4")

        let sut = makeSUT()

        sut.loadNodeAndMonitorUpdate(for: node2, monitor: [node1, node2, node3])

        await _ = sut.monitorVideoNodesUpdateTask?.value

        sut.playNext()

        #expect(sut.nodeName == node3.name)
    }

    @Test
    func playNext_whenAtEnd_shouldDoNothing() async {
        let node1 = MockPlayableNode(handle: 1, name: "v1.mp4")
        let node2 = MockPlayableNode(handle: 2, name: "v2.mp4")
        let sut = makeSUT()
        sut.loadNodeAndMonitorUpdate(for: node2, monitor: [node1, node2])

        await _ = sut.monitorVideoNodesUpdateTask?.value

        sut.playNext()

        #expect(sut.nodeName == node2.name)
    }

    @Test
    func playPrevious_whenInMiddle_shouldLoadPreviousNode() async {
        let node1 = MockPlayableNode(handle: 1, name: "v1.mp4")
        let node2 = MockPlayableNode(handle: 2, name: "v2.mp4")
        let node3 = MockPlayableNode(handle: 3, name: "v3.mp4")
        let sut = makeSUT()

        sut.loadNodeAndMonitorUpdate(for: node2, monitor: [node1, node2, node3])

        await _ = sut.monitorVideoNodesUpdateTask?.value

        sut.playPrevious()

        #expect(sut.nodeName == node1.name)
    }

    @Test
    func playPrevious_whenAtStart_shouldStillPlayTheCurrentVideo() async {
        let node1 = MockPlayableNode(handle: 1, name: "v1.mp4")
        let node2 = MockPlayableNode(handle: 2, name: "v2.mp4")
        let sut = makeSUT()

        sut.loadNodeAndMonitorUpdate(for: node1, monitor: [node1, node2])

        await _ = sut.monitorVideoNodesUpdateTask?.value

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
