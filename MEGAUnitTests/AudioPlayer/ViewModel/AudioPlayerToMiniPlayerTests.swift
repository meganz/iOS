@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite
struct AudioPlayerToMiniPlayerTests {
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        playerHandler: MockAudioPlayerHandler
    ) -> (sut: AudioPlayerViewModel, router: ForwardingAudioPlayerViewRouterMock) {
        let router = ForwardingAudioPlayerViewRouterMock(handler: playerHandler)
        let sut = AudioPlayerViewModel(
            configEntity: configEntity,
            playerHandler: playerHandler,
            router: router,
            nodeInfoUseCase: MockNodeInfoUseCase(),
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            offlineInfoUseCase: OfflineFileInfoUseCase(),
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(),
            audioPlayerUseCase: MockAudioPlayerUseCase(),
            accountUseCase: MockAccountUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            tracker: MockTracker()
        )
        return (sut, router)
    }

    private func audioPlayerConfigEntity(
        node: MockNode,
        isFolderLink: Bool = false,
        relatedFiles: [String]? = nil,
        fileLink: String? = nil,
        allNodes: [MEGANode]? = nil
    ) -> AudioPlayerConfigEntity {
        AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            relatedFiles: relatedFiles,
            allNodes: allNodes
        )
    }
    
    @Test
    func testDispatchInitMiniPlayer_withCurrentItemNode_callsPlayerHandlerInitMiniPlayer() {
        let handler = MockAudioPlayerHandler()
        let node = MockNode(handle: 1)
        handler.mockPlayerCurrentItem = AudioPlayerItem(
            name: "track",
            url: URL(string: "https://example.com/audio.mp3")!,
            node: node
        )
        let config = audioPlayerConfigEntity(node: node, isFolderLink: false)
        let (sut, router) = makeSUT(configEntity: config, playerHandler: handler)
        
        sut.dispatch(.initMiniPlayer)
        
        #expect(router.showMiniPlayer_calledTimes == 1)
        #expect(handler.initMiniPlayerCallCount == 1)
    }
    
    @Test
    func testDispatchInitMiniPlayer_withoutCurrentItemNode_callsPlayerHandlerInitMiniPlayer() {
        let handler = MockAudioPlayerHandler()
        let node = MockNode(handle: 1)
        let config = audioPlayerConfigEntity(node: node, isFolderLink: false)
        let (sut, router) = makeSUT(configEntity: config, playerHandler: handler)
        
        sut.dispatch(.initMiniPlayer)
        
        #expect(router.showMiniPlayer_calledTimes == 1)
        #expect(handler.initMiniPlayerCallCount == 1)
    }
    
    @Test
    func testDispatchInitMiniPlayer_withFileLink_callsPlayerHandlerInitMiniPlayer() {
        let handler = MockAudioPlayerHandler()
        let config = AudioPlayerConfigEntity(fileLink: "file_path_or_link")
        let (sut, router) = makeSUT(configEntity: config, playerHandler: handler)
        
        sut.dispatch(.initMiniPlayer)
        
        #expect(router.showMiniPlayer_calledTimes == 1)
        #expect(handler.initMiniPlayerCallCount == 1)
    }
}
