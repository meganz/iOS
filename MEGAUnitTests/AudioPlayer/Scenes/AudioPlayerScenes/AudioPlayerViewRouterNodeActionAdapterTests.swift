@preconcurrency @testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("AudioPlayerViewRouterNodeActionAdapter")
struct AudioPlayerViewRouterNodeActionAdapterTests {
    
    @Test("from file link -> forwards to AudioPlayerViewController")
    func fileLinkForwardsToAudioPlayerVC() {
        let link = "any-file-link"
        let (sut, vc) = makeSUT(config: makeConfig(origin: .fileLink, fileLink: link))
        
        sut.nodeAction(makeNodeActionVC(), didSelect: .rename, for: MockNode(handle: 1), from: "any-sender")
        
        guard let generic = sut.nodeActionViewControllerDelegate as? MockNodeActionViewControllerGenericDelegate else {
            Issue.record("Expected MockNodeActionViewControllerGenericDelegate")
            return
        }
        #expect(generic.didSelectNodeActionCallCount == 0)
        #expect(vc.didSelectNodeActionTypeMenuCallCount == 1)
    }
    
    @Test(
        "from non-file link -> forwards to generic delegate",
        arguments: [
            AudioPlayerConfigEntity.NodeOriginType.folderLink,
            .chat,
            .unknown
        ]
    )
    func nonFileLinkForwardsToGenericDelegate(origin: AudioPlayerConfigEntity.NodeOriginType) {
        let (sut, vc) = makeSUT(config: makeConfig(origin: origin))
        
        sut.nodeAction(makeNodeActionVC(), didSelect: .rename, for: MockNode(handle: 1), from: "any-sender")
        
        guard let generic = sut.nodeActionViewControllerDelegate as? MockNodeActionViewControllerGenericDelegate else {
            Issue.record("Expected MockNodeActionViewControllerGenericDelegate for origin \(origin)")
            return
        }
        #expect(generic.didSelectNodeActionCallCount == 1, "Origin \(origin) should call generic delegate once")
        #expect(vc.didSelectNodeActionTypeMenuCallCount == 0, "Origin \(origin) should not call AudioPlayer VC")
    }
    
    // MARK: - Shared Helpers
    
    @MainActor
    private func makeSUT(
        config: AudioPlayerConfigEntity
    ) -> (sut: AudioPlayerViewRouterNodeActionAdapter, vc: MockAudioPlayerViewController) {
        let vc = makeAudioPlayerVC()
        let sut = AudioPlayerViewRouterNodeActionAdapter(
            configEntity: config,
            nodeActionViewControllerDelegate: MockNodeActionViewControllerGenericDelegate(
                viewController: UIViewController(),
                moveToRubbishBinViewModel: MockMoveToRubbishBinViewModel()
            ),
            fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate(link: "any-link", viewController: UIViewController()),
            audioPlayerViewController: vc
        )
        return (sut, vc)
    }
    
    @MainActor
    private func makeNodeActionVC() -> NodeActionViewController {
        NodeActionViewController(
            node: MockNode(handle: 1),
            delegate: MockNodeActionViewControllerGenericDelegate(
                viewController: UIViewController(),
                moveToRubbishBinViewModel: MockMoveToRubbishBinViewModel()
            ),
            displayMode: .albumLink,
            isInVersionsView: false,
            isBackupNode: false,
            sender: "any-sender"
        )
    }
    
    private func makeConfig(
        origin: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil
    ) -> AudioPlayerConfigEntity {
        let node = MockNode(handle: .max)
        return switch origin {
        case .folderLink:
            AudioPlayerConfigEntity(node: node, isFolderLink: true, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles)
        case .fileLink:
            AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: fileLink, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles)
        case .chat:
            AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, relatedFiles: relatedFiles)
        case .unknown:
            AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles)
        }
    }
    
    @MainActor
    private func makeAudioPlayerVC() -> MockAudioPlayerViewController {
        let storyboard = UIStoryboard(name: "AudioPlayer", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "AudioPlayerViewControllerID") { coder in
            let config = AudioPlayerConfigEntity()
            return MockAudioPlayerViewController(
                coder: coder,
                viewModel: AudioPlayerViewModel(
                    configEntity: config,
                    playerHandler: MockAudioPlayerHandler(),
                    router: MockAudioPlayerViewRouter(),
                    nodeInfoUseCase: MockNodeInfoUseCase(),
                    streamingInfoUseCase: MockStreamingInfoUseCase(),
                    offlineInfoUseCase: OfflineFileInfoUseCase(),
                    playbackContinuationUseCase: MockPlaybackContinuationUseCase(),
                    audioPlayerUseCase: MockAudioPlayerUseCase(),
                    accountUseCase: MockAccountUseCase(),
                    networkMonitorUseCase: MockNetworkMonitorUseCase(),
                    tracker: MockTracker()
                )
            )
        }
        guard let typed = vc as? MockAudioPlayerViewController else {
            Issue.record("Failed to instantiate AudioPlayerViewController from storyboard")
            fatalError()
        }
        return typed
    }
}

private final class MockNodeActionViewControllerGenericDelegate: NodeActionViewControllerGenericDelegate {
    private(set) var didSelectNodeActionCallCount = 0
    
    override func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        didSelectNodeActionCallCount += 1
    }
}

private final class MockAudioPlayerViewController: AudioPlayerViewController {
    private(set) var didSelectNodeActionTypeMenuCallCount = 0
    
    override func didSelectNodeActionTypeMenu(_ nodeActionTypeEntity: NodeActionTypeEntity) {
        didSelectNodeActionTypeMenuCallCount += 1
    }
}
