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
    enum Scenario: String, CaseIterable {
        case currentItemWithNode
        case noCurrentItem
        case fileLink
    }
    
    private let url = URL(string: "https://example.com/audio.mp3")!
    private let handler = MockAudioPlayerHandler()
    private let node = MockNode(handle: 1)
    
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
    
    @Test("Dispatching `.initMiniPlayer` shows the mini-player and initializes the handler for every scenario (current item, no current item, or file link)", arguments: Scenario.allCases)
    func initMiniPlayerCallsHandlerAndShowsMiniPlayer(_ scenario: Scenario) {
        let config: AudioPlayerConfigEntity
        
        switch scenario {
        case .currentItemWithNode:
            handler.mockPlayerCurrentItem = AudioPlayerItem(name: "track", url: url, node: node)
            config = audioPlayerConfigEntity(node: node, isFolderLink: false)
        case .noCurrentItem:
            config = audioPlayerConfigEntity(node: node, isFolderLink: false)
        case .fileLink:
            config = AudioPlayerConfigEntity(fileLink: "file_path_or_link")
        }
        
        let (sut, router) = makeSUT(configEntity: config, playerHandler: handler)
        sut.dispatch(.initMiniPlayer)
        
        #expect(router.showMiniPlayer_calledTimes == 1, "Scenario: \(scenario.rawValue)")
        #expect(handler.initMiniPlayerCallCount == 1, "Scenario: \(scenario.rawValue)")
    }
}
