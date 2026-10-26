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

        mockUseCase.savePlaybackPosition(savedPosition, for: .node(mockNode))

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
    func loadNode_whenNodeHasNoLocalCopyAndServerAlreadyRunning_shouldStillHoldIt() async {
        let streamingUseCase = MockStreamingUseCase()
        streamingUseCase.isStreaming = true
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in nil })

        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        #expect(streamingUseCase.startStreamingCallCount == 1)
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

    // MARK: - Offline files

    @Test
    func loadOfflineFile_shouldPlayItFromTheDeviceWithoutStreaming() async {
        let streamingUseCase = MockStreamingUseCase()
        let file = URL(fileURLWithPath: "/offline/v1.mp4")
        let sut = makeSUT(streamingUseCase: streamingUseCase)

        sut.loadItemAndMonitorUpdate(for: .offlineFile(url: file), monitor: [])

        #expect(sut.nodeName == "v1.mp4")
        #expect(streamingUseCase.startStreamingCallCount == 0)
        #expect(streamingUseCase.streamingLinkCallCount == 0)
        #expect(sut.state != .error("Failed to get streaming link for node"))
    }

    @Test
    func loadOfflineFile_shouldNotMonitorNodeUpdates_asNoCloudNodeBacksIt() async {
        let sut = makeSUT()

        sut.loadItemAndMonitorUpdate(for: .offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4")), monitor: [])

        #expect(sut.monitorVideoNodesUpdateTask == nil)
    }

    @Test
    func loadOfflineFile_whenHasSavedPosition_shouldResumeFromIt() async {
        let mockUseCase = MockResumePlaybackPositionUseCase()
        let file = VideoPlaybackItem.offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4"))
        mockUseCase.savePlaybackPosition(120.5, for: file)
        let sut = makeSUT(resumePlaybackPositionUseCase: mockUseCase)

        sut.loadItemAndMonitorUpdate(for: file, monitor: [])

        #expect(mockUseCase.getPlaybackPositionCallCount == 1)
    }

    @Test
    func playNext_withAQueueOfOfflineFiles_shouldPlayTheNextFile() async {
        let file1 = VideoPlaybackItem.offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4"))
        let file2 = VideoPlaybackItem.offlineFile(url: URL(fileURLWithPath: "/offline/v2.mp4"))
        let sut = makeSUT()

        sut.loadItemAndMonitorUpdate(for: file1, monitor: [file1, file2])

        #expect(sut.canPlayNext == true)

        sut.playNext()

        #expect(sut.nodeName == "v2.mp4")
        #expect(sut.canPlayNext == false)
    }

    @Test
    func playPrevious_withAQueueOfOfflineFiles_shouldPlayThePreviousFile() async {
        let file1 = VideoPlaybackItem.offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4"))
        let file2 = VideoPlaybackItem.offlineFile(url: URL(fileURLWithPath: "/offline/v2.mp4"))
        let sut = makeSUT()

        sut.loadItemAndMonitorUpdate(for: file2, monitor: [file1, file2])
        sut.playPrevious()

        #expect(sut.nodeName == "v1.mp4")
    }

    @Test
    func currentNode_whilePlayingAnOfflineFile_shouldBeNil_asThereIsNoNodeToActOn() async {
        let sut = makeSUT()

        sut.loadItemAndMonitorUpdate(for: .offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4")), monitor: [])

        #expect(sut.currentNode == nil)
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

    @Test
    func stop_afterStreaming_shouldStopTheStreamingServer() async {
        let streamingUseCase = MockStreamingUseCase()
        let sut = makeSUT(streamingUseCase: streamingUseCase, localFileURL: { _ in nil })
        sut.loadNodeAndMonitorUpdate(for: MockPlayableNode(name: "v1.mp4"), monitor: [MockPlayableNode]())

        sut.stop()

        #expect(streamingUseCase.stopStreamingCallCount == 1)
    }

    @Test
    func stop_afterStreamingAndThenPlayingALocalCopy_shouldStopTheStreamingServer() async {
        let streamingUseCase = MockStreamingUseCase()
        let streamedNode = MockPlayableNode(handle: 1, name: "v1.mp4")
        let downloadedNode = MockPlayableNode(handle: 2, name: "v2.mp4")
        let localFile = URL(fileURLWithPath: "/local/v2.mp4")
        let sut = makeSUT(
            streamingUseCase: streamingUseCase,
            localFileURL: { $0.handle == downloadedNode.handle ? localFile : nil }
        )
        sut.loadNodeAndMonitorUpdate(for: streamedNode, monitor: [streamedNode, downloadedNode])
        await _ = sut.monitorVideoNodesUpdateTask?.value
        sut.playNext()

        sut.stop()

        #expect(streamingUseCase.startStreamingCallCount == 1)
        #expect(streamingUseCase.stopStreamingCallCount == 1)
    }

    @Test
    func playOfflineFile_shouldNotStartTheStreamingServer() async {
        let streamingUseCase = MockStreamingUseCase()
        let sut = makeSUT(streamingUseCase: streamingUseCase)

        sut.loadItemAndMonitorUpdate(for: .offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4")), monitor: [])

        #expect(streamingUseCase.startStreamingCallCount == 0)
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

    // MARK: - Continue where you left off

    @Test
    func stop_whenPositionIsResumable_shouldRecordLeftOffItem() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let node = MockPlayableNode(handle: 42, name: "resumable.mp4")
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)
        sut.currentItem = .node(node)
        sut.currentTime = .seconds(20)
        sut.duration = .seconds(60)
        sut.state = .playing

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.map(\.handle) == [42])
        #expect(recordUseCase.record_Calls.map(\.name) == ["resumable.mp4"])
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test
    func stop_whenPositionIsTooEarly_shouldRemoveLeftOffItem() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let node = MockPlayableNode(handle: 42, name: "too_early.mp4")
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)
        sut.currentItem = .node(node)
        sut.currentTime = .seconds(5)
        sut.duration = .seconds(60)
        sut.state = .playing

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.remove_Calls == [42])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    @Test
    func stop_whenAlmostFinished_shouldRemoveLeftOffItem() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let node = MockPlayableNode(handle: 42, name: "almost_done.mp4")
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)
        sut.currentItem = .node(node)
        sut.currentTime = .seconds(59)
        sut.duration = .seconds(60)
        sut.state = .playing

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.remove_Calls == [42])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    @Test
    func stop_whenDurationIsUnknown_shouldNotTouchLeftOffItem() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let node = MockPlayableNode(handle: 42, name: "unknown_duration.mp4")
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)
        sut.currentItem = .node(node)

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test
    func stop_whenPlayedButTooEarly_shouldDeleteTheSavedPosition() async {
        let resumeUseCase = MockResumePlaybackPositionUseCase()
        let item = VideoPlaybackItem.node(MockPlayableNode(handle: 42, name: "too_early.mp4", fingerprint: "fingerprint123"))
        resumeUseCase.savePlaybackPosition(1200, for: item)
        let sut = makeSUT(resumePlaybackPositionUseCase: resumeUseCase)
        sut.currentItem = item
        sut.currentTime = .seconds(5)
        sut.duration = .seconds(60)
        sut.state = .playing

        sut.stop()

        #expect(resumeUseCase.savedPositions[item.playbackID] == nil)
    }

    @Test
    func stop_beforePlaybackStarts_shouldKeepTheSavedPosition() async {
        let resumeUseCase = MockResumePlaybackPositionUseCase()
        let file = VideoPlaybackItem.offlineFile(url: URL(fileURLWithPath: "/offline/v1.mp4"))
        resumeUseCase.savePlaybackPosition(1200, for: file)
        let sut = makeSUT(resumePlaybackPositionUseCase: resumeUseCase)
        sut.loadItemAndMonitorUpdate(for: file, monitor: [])
        sut.duration = .seconds(3600)

        sut.stop()

        #expect(resumeUseCase.savedPositions[file.playbackID] == 1200)
    }

    @Test
    func stop_whenNoNodeLoaded_shouldNotTouchLeftOffItem() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        sut.stop()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test
    func playNext_whenPositionIsResumable_shouldRecordOutgoingNode() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let node1 = MockPlayableNode(handle: 1, name: "v1.mp4")
        let node2 = MockPlayableNode(handle: 2, name: "v2.mp4")
        let node3 = MockPlayableNode(handle: 3, name: "v3.mp4")
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)
        sut.loadNodeAndMonitorUpdate(for: node2, monitor: [node1, node2, node3])
        await _ = sut.monitorVideoNodesUpdateTask?.value
        sut.currentTime = .seconds(20)
        sut.duration = .seconds(60)
        sut.state = .playing

        sut.playNext()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.map(\.handle) == [2])
        #expect(sut.nodeName == "v3.mp4")
    }

    @Test
    func playPrevious_whenPositionIsResumable_shouldRecordOutgoingNode() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let node1 = MockPlayableNode(handle: 1, name: "v1.mp4")
        let node2 = MockPlayableNode(handle: 2, name: "v2.mp4")
        let node3 = MockPlayableNode(handle: 3, name: "v3.mp4")
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)
        sut.loadNodeAndMonitorUpdate(for: node2, monitor: [node1, node2, node3])
        await _ = sut.monitorVideoNodesUpdateTask?.value
        sut.currentTime = .seconds(20)
        sut.duration = .seconds(60)
        sut.state = .playing

        sut.playPrevious()
        await sut.leftOffItemTask?.value

        #expect(recordUseCase.record_Calls.map(\.handle) == [2])
        #expect(sut.nodeName == "v1.mp4")
    }

    private func makeSUT(
        streamingUseCase: some StreamingUseCaseProtocol = MockStreamingUseCase(),
        localFileURL: @escaping @Sendable (any PlayableNode) -> URL? = { _ in nil },
        resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol = MockResumePlaybackPositionUseCase(),
        videoNodesUseCase: some VideoNodesUseCaseProtocol =
            MockVideoNodesUseCase(),
        videoPlaybackLoopUseCase: some VideoPlaybackLoopUseCaseProtocol = MockVideoPlaybackLoopUseCase(),
        leftOffItemRecordUseCase: (any LeftOffItemRecordUseCaseProtocol)? = MockLeftOffItemRecordUseCase()
    ) -> MEGAAVPlayer {
        return MEGAAVPlayer(
            streamingUseCase: streamingUseCase,
            localFileURL: localFileURL,
            notificationCenter: .default,
            resumePlaybackPositionUseCase: resumePlaybackPositionUseCase,
            videoNodesUseCase: videoNodesUseCase,
            videoPlaybackLoopUseCase: videoPlaybackLoopUseCase,
            leftOffItemRecordUseCase: leftOffItemRecordUseCase
        )
    }
}
