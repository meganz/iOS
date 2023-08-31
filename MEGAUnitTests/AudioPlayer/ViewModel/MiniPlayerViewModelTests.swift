import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

final class MiniPlayerViewModelTests: XCTestCase {
    private var mockRouter = MockMiniPlayerViewRouter()
    private var mockPlayerHandler = MockAudioPlayerHandler()
    private var mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
    
    func testAudioPlayerActions() {
        let (viewModel, _, _) = makeSUT()
        test(viewModel: viewModel, action: .onViewDidLoad, expectedCommands: [.showLoading(false),
                                                                             .initTracks(currentItem: AudioPlayerItem.mockItem, queue: nil, loopMode: false)])
        XCTAssertEqual(mockPlayerHandler.addPlayerListener_calledTimes, 1)
        
        test(viewModel: viewModel, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(mockPlayerHandler.togglePlay_calledTimes, 1)
        
        test(viewModel: viewModel, action: .playItem(AudioPlayerItem.mockItem), expectedCommands: [])
        XCTAssertEqual(mockPlayerHandler.playItem_calledTimes, 1)
        
        test(viewModel: viewModel, action: .deinit, expectedCommands: [])
        XCTAssertEqual(mockPlayerHandler.removePlayerListener_calledTimes, 1)
    }
    
    func testRouterActions() {
        let (viewModel, _, _) = makeSUT()
        test(viewModel: viewModel, action: .onClose, expectedCommands: [])
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
        
        test(viewModel: viewModel, action: .showPlayer(MEGANode(), nil), expectedCommands: [])
        XCTAssertEqual(mockRouter.showPlayer_calledTimes, 1)
    }
    
    func testAudioDidStartPlayingItem_shouldResumePlayback_whenStatusNotStartFromBeginning() {
        func assert(
            whenContinuationStatus continuationStatus: PlaybackContinuationStatusEntity,
            expectedPlayerResumePlaybackCalls: [TimeInterval],
            line: UInt = #line
        ) {
            let (viewModel, _, _) = makeSUT()
            mockPlaybackContinuationUseCase._status = continuationStatus
            
            viewModel.audioDidStartPlayingItem(testItem)
            
            XCTAssertEqual(
                mockPlayerHandler.playerResumePlayback_Calls,
                expectedPlayerResumePlaybackCalls,
                line: line
            )
        }
        
        assert(
            whenContinuationStatus: .startFromBeginning,
            expectedPlayerResumePlaybackCalls: []
        )
        assert(
            whenContinuationStatus: .displayDialog(playbackTime: 1234.0),
            expectedPlayerResumePlaybackCalls: [1234.0]
        )
        assert(
            whenContinuationStatus: .resumeSession(playbackTime: 3456.0),
            expectedPlayerResumePlaybackCalls: [3456.0]
        )
    }
    
    func testOnViewDidLoad_onViewDidLoad_registerSdk() {
        let (onlineSUT, audioPlayerUseCase, _) = makeSUT()
        
        onlineSUT.dispatch(.onViewDidLoad)
        
        XCTAssertEqual(audioPlayerUseCase.registerMEGADelegateCallCount, 1)
    }
    
    func testOnNodesUpdate_whenHasUpdatedItemButNotFoundNodeInList_ShouldNotRefresh() {
        let firstAudioNode = MockNode(handle: 1, name: "first-audio", nodeType: .file)
        let latestAudioNode = MockNode(handle: 2, name: "latest-audio", nodeType: .file)
        let updatedNode = MockNode(handle: 3, name: "New name")
        let updatedItem: AudioPlayerItem = .mockItem(node: updatedNode)
        let (onlineSUT, audioPlayerUseCase, sdk) = makeSUT(
            node: firstAudioNode,
            allNodes: [firstAudioNode, latestAudioNode]
        )
        let exp = expectation(description: "wait")
        var invokedCommands = [MiniPlayerViewModel.Command]()
        onlineSUT.invokeCommand = { invokedCommands.append($0) }
        
        audioPlayerUseCase.simulateOnNodesUpdate(MockNodeList(nodes: [updatedNode]), sdk: sdk)
        exp.fulfill()
        wait(for: [exp], timeout: 0.2)
        
        XCTAssertEqual(invokedCommands.count, 0)
        let receivedItems = invokedCommands.reloadedItems()
        XCTAssertFalse(receivedItems.contains(updatedItem), "Expect to not contain updated node. We do not want to update node when node is not on the list.")
        assertThatRefreshItemDataSourceIsNotUpdated(on: onlineSUT, updatedNode: updatedNode, latestAudioNode: latestAudioNode)
    }
    
    func testOnNodesUpdate_whenHasUpdatedItemAndNotShowingCurrentItem_refresh() {
        let firstAudioNode = MockNode(handle: 1, name: "first-audio", nodeType: .file)
        let latestAudioNode = MockNode(handle: 2, name: "latest-audio", nodeType: .file)
        let updatedNode = MockNode(handle: 1, name: "New name")
        let expectedItem: AudioPlayerItem = .mockItem(node: updatedNode)
        let (onlineSUT, audioPlayerUseCase, sdk) = makeSUT(
            node: firstAudioNode,
            allNodes: [firstAudioNode, latestAudioNode]
        )
        let exp = expectation(description: "wait")
        var invokedCommands = [MiniPlayerViewModel.Command]()
        onlineSUT.invokeCommand = { invokedCommands.append($0) }
        
        simulateOnNodesUpdate(audioPlayerUseCase, updatedNode, sdk, latestAudioNode)
        exp.fulfill()
        wait(for: [exp], timeout: 1)
        
        assertThatRefreshItemReloadNonCurrentItem(invokedCommands: invokedCommands, expectedItem: expectedItem)
        assertThatRefreshItemDataSourceUpdated(on: onlineSUT, updatedNode: updatedNode, latestAudioNode: latestAudioNode)
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        node: MEGANode? = nil,
        allNodes: [MEGANode]? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: MiniPlayerViewModel, audioPlayerUseCase: MockAudioPlayerUseCase, sdk: MockSdk) {
        mockRouter = MockMiniPlayerViewRouter()
        mockPlayerHandler = MockAudioPlayerHandler()
        mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
        let tracks = allNodes?.compactMap { AudioPlayerItem(name: $0.name ?? "", url: URL(string: "www.any-url.com")!, node: $0) }
        let player = AudioPlayer()
        player.tracks = tracks ?? []
        mockPlayerHandler.setCurrent(player: player, autoPlayEnabled: false, tracks: tracks ?? [])
        let mockAudioPlayerUseCase = MockAudioPlayerUseCase()
        let sdk = MockSdk(nodes: allNodes ?? [])
        let sut = MiniPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(
                node: node,
                isFolderLink: false,
                fileLink: nil,
                relatedFiles: nil,
                allNodes: allNodes,
                playerHandler: mockPlayerHandler
            ),
            router: mockRouter,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: mockPlaybackContinuationUseCase,
            audioPlayerUseCase: mockAudioPlayerUseCase,
            sdk: sdk
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockAudioPlayerUseCase, sdk)
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
    private func simulateOnNodesUpdate(_ audioPlayerUseCase: MockAudioPlayerUseCase, _ updatedNode: MockNode, _ sdk: MockSdk, _ latestAudioNode: MockNode) {
        audioPlayerUseCase.simulateOnNodesUpdate(MockNodeList(nodes: [updatedNode]), sdk: sdk)
        let tracks = [updatedNode, latestAudioNode].compactMap { AudioPlayerItem(name: $0.name ?? "", url: URL(string: "www.any-url.com")!, node: $0) }
        let player = AudioPlayer()
        player.tracks = tracks
        mockPlayerHandler.setCurrent(player: player, autoPlayEnabled: false, tracks: tracks)
    }
    
    private func assertThatRefreshItemReloadNonCurrentItem(
        invokedCommands: [MiniPlayerViewModel.Command],
        expectedItem: AudioPlayerItem,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(invokedCommands.count, 1, file: file, line: line)
        guard let command = invokedCommands.first else {
            XCTFail("Fail to get command", file: file, line: line)
            return
        }
        
        switch command {
        case .reloadAt:
            break
        default:
            XCTFail("Expect to get reload command, got other command instead.", file: file, line: line)
        }
    }
    
    private func assertThatRefreshItemReloadCurrentItem(
        invokedCommands: [MiniPlayerViewModel.Command],
        expectedItem: AudioPlayerItem,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(invokedCommands.count, 1, file: file, line: line)
        guard let command = invokedCommands.first else {
            XCTFail("Fail to get command", file: file, line: line)
            return
        }
        
        switch command {
        case .reload(let currentItem):
            XCTAssertEqual(currentItem.name, expectedItem.name, file: file, line: line)
            XCTAssertEqual(currentItem.url, expectedItem.url, file: file, line: line)
        default:
            XCTFail("Expect to get reload command, got other command instead.", file: file, line: line)
        }
    }
    
    private func assertThatRefreshItemDataSourceIsNotUpdated(
        on onlineSUT: MiniPlayerViewModel,
        updatedNode: MEGANode,
        latestAudioNode: MEGANode,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotEqual(onlineSUT.configEntity.node, updatedNode, file: file, line: line)
        onlineSUT.configEntity.playerHandler.currentPlayer()?.tracks
            .map { $0.name }
            .enumerated()
            .forEach { (index, name) in
                if index == 1 {
                    XCTAssertNotEqual(name, updatedNode.name, file: file, line: line)
                }
                if index == 2 {
                    XCTAssertEqual(name, latestAudioNode.name, file: file, line: line)
                }
            }
    }
    
    private func assertThatRefreshItemDataSourceUpdated(
        on onlineSUT: MiniPlayerViewModel,
        updatedNode: MEGANode,
        latestAudioNode: MEGANode,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(onlineSUT.configEntity.node, updatedNode, file: file, line: line)
        onlineSUT.configEntity.playerHandler.currentPlayer()?.tracks
            .map { $0.name }
            .enumerated()
            .forEach { (index, name) in
                if index == 0 {
                    XCTAssertEqual(name, updatedNode.name, "fail at index: \(index)", file: file, line: line)
                }
                if index == 1 {
                    XCTAssertEqual(name, latestAudioNode.name, "fail at index: \(index)", file: file, line: line)
                }
            }
    }
    
}

private extension Array where Element == MiniPlayerViewModel.Command {
    
    func reloadedItems(file: StaticString = #filePath, line: UInt = #line) -> [AudioPlayerItem] {
        var receivedItems = [AudioPlayerItem]()
        enumerated().forEach { (index, command) in
            switch command {
            case .reload(let currentItem):
                receivedItems.append(currentItem)
            default:
                XCTFail("Expect to got reload command, got other command instead: \(command) at index: \(index)", file: file, line: line)
            }
        }
        return receivedItems
    }
}
