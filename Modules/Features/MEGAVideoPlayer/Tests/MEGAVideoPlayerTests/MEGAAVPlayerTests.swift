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

    // MARK: - Local file playback

    @Test
    func loadNode_whenNodeHasLocalCopy_shouldPlayItWithoutStreaming() async {
        let streamingUseCase = MockStreamingUseCase()
        let localFile = URL(fileURLWithPath: "/tmp/v1.mp4")
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in localFile })

        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        #expect(streamingUseCase.startStreamingCallCount == 0)
        #expect(streamingUseCase.streamingLinkCallCount == 0)
    }

    @Test
    func loadNode_whenNodeHasNoLocalCopy_shouldStartStreamingServerAndAskForALink() async {
        let streamingUseCase = MockStreamingUseCase()
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in nil })

        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        #expect(streamingUseCase.startStreamingCallCount == 1)
        #expect(streamingUseCase.streamingLinkCallCount == 1)
    }

    @Test
    func loadNode_whenNodeHasNoLocalCopyAndServerAlreadyRunning_shouldNotStartItAgain() async {
        let streamingUseCase = MockStreamingUseCase()
        streamingUseCase.isStreaming = true
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in nil })

        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        #expect(streamingUseCase.startStreamingCallCount == 0)
        #expect(streamingUseCase.streamingLinkCallCount == 1)
    }

    @Test
    func loadNode_whenNodeHasNoLocalCopyAndNoStreamingLink_shouldReportError() async {
        let streamingUseCase = MockStreamingUseCase()
        streamingUseCase.streamingLink = nil
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in nil })

        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        #expect(sut.state == .error("Failed to get streaming link for node"))
    }

    @Test
    func replayCurrentNode_whenNodeHasLocalCopy_shouldReplayItWithoutStreaming() async {
        let streamingUseCase = MockStreamingUseCase()
        let localFile = URL(fileURLWithPath: "/tmp/v1.mp4")
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in localFile })
        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        sut.replayCurrentNode()

        #expect(streamingUseCase.startStreamingCallCount == 0)
        #expect(streamingUseCase.streamingLinkCallCount == 0)
    }

    // MARK: - Helper

    @Test
    func loadNode_shouldResetThrottleInheritedFromPreviousItem() async {
        let streamingUseCase = MockStreamingUseCase()
        let sut = makeSUT(streamingUseCase: streamingUseCase)

        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        #expect(streamingUseCase.resetThrottleBitrateCallCount == 1)
    }

    @Test
    func stop_shouldResetThrottleSoItDoesNotOutliveThePlayback() async {
        let streamingUseCase = MockStreamingUseCase()
        let sut = makeSUT(streamingUseCase: streamingUseCase)
        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        sut.stop()

        #expect(streamingUseCase.resetThrottleBitrateCallCount == 2)
    }

    // MARK: - Loop Tests

    @Test(arguments: [true, false])
    func init_restoresPersistedLoopState(_ persistedValue: Bool) {
        let sut = makeSUT(
            videoPlaybackLoopUseCase: MockVideoPlaybackLoopUseCase(isLoopEnabled: persistedValue)
        )

        #expect(sut.isLoopEnabled == persistedValue)
    }

    @Test
    func setLooping_persistsLoopState() {
        let mockLoopUseCase = MockVideoPlaybackLoopUseCase()
        let sut = makeSUT(videoPlaybackLoopUseCase: mockLoopUseCase)

        sut.setLooping(true)
        #expect(sut.isLoopEnabled == true)
        #expect(mockLoopUseCase.setLoopEnabledCallCount == 1)
        #expect(mockLoopUseCase.isLoopEnabled == true)

        sut.setLooping(false)
        #expect(sut.isLoopEnabled == false)
        #expect(mockLoopUseCase.setLoopEnabledCallCount == 2)
        #expect(mockLoopUseCase.isLoopEnabled == false)
    }

    private func makeSUT(
        streamingUseCase: some StreamingUseCaseProtocol = MockStreamingUseCase(),
        localFileURL: @escaping @Sendable (any PlayableNode) -> URL? = { _ in nil },
        resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol = MockResumePlaybackPositionUseCase(),
        videoNodesUseCase: some VideoNodesUseCaseProtocol =
            MockVideoNodesUseCase(),
        videoPlaybackLoopUseCase: some VideoPlaybackLoopUseCaseProtocol = MockVideoPlaybackLoopUseCase()
    ) -> MEGAAVPlayer {
        return MEGAAVPlayer(
            streamingUseCase: streamingUseCase,
            localFileURL: localFileURL,
            notificationCenter: .default,
            resumePlaybackPositionUseCase: resumePlaybackPositionUseCase,
            videoNodesUseCase: videoNodesUseCase,
            videoPlaybackLoopUseCase: videoPlaybackLoopUseCase
        )
    }
}
