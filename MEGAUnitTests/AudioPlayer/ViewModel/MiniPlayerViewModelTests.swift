@testable import MEGA
import MEGADataMock
import MEGADomain
import MEGADomainMock
import XCTest

final class MiniPlayerViewModelTests: XCTestCase {
    private var mockRouter = MockMiniPlayerViewRouter()
    private var mockPlayerHandler = MockAudioPlayerHandler()
    private var mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
    
    func testAudioPlayerActions() {
        let viewModel = makeSUT()
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
        let viewModel = makeSUT()
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
            let viewModel = makeSUT()
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
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> MiniPlayerViewModel {
        mockRouter = MockMiniPlayerViewRouter()
        mockPlayerHandler = MockAudioPlayerHandler()
        mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
        let sut = MiniPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(
                node: nil,
                isFolderLink: false,
                fileLink: nil,
                relatedFiles: nil,
                playerHandler: mockPlayerHandler
            ),
            router: mockRouter,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository()),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: mockPlaybackContinuationUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
}
