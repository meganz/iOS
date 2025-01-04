@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerViewRouterNodeActionAdapterTests: XCTestCase {
    
    @MainActor
    func testNodeAction_fromFileLinkNode_fordwardsCorrectDelegate() {
        let link = "any-file-link"
        let (sut, audioPlayerViewController) = makeSUT(configEntity: audioPlayerConfigEntity(from: .fileLink, fileLink: link, relatedFiles: nil))
        
        sut.nodeAction(mockNodeActionViewController(), didSelect: .rename, for: MockNode(handle: 1), from: "any-sender")
        
        guard let mockNodeActionDelegate = sut.nodeActionViewControllerDelegate as? MockNodeActionViewControllerGenericDelegate else {
            XCTFail("Expect to have mock type of : \(type(of: MockNodeActionViewControllerGenericDelegate.self))")
            return
        }
        XCTAssertEqual(mockNodeActionDelegate.didSelectNodeActionCallCount, 0)
        XCTAssertEqual(audioPlayerViewController.didSelectNodeActionTypeMenuCallCount, 1)
    }
    
    @MainActor
    func testNodeAction_fromNonFileLinkNode_fordwardsCorrectDelegate() {
        AudioPlayerConfigEntity.NodeOriginType.allCases
            .filter { $0 == .fileLink }
            .map { audioPlayerConfigEntity(from: $0) }
            .enumerated()
            .forEach { (index, configEntity) in
                
                let (sut, audioPlayerViewController) = makeSUT(configEntity: configEntity)
                
                sut.nodeAction(mockNodeActionViewController(), didSelect: .rename, for: MockNode(handle: 1), from: "any-sender")
                
                guard let mockNodeActionDelegate = sut.nodeActionViewControllerDelegate as? MockNodeActionViewControllerGenericDelegate else {
                    XCTFail("Expect to have mock type of : \(type(of: MockNodeActionViewControllerGenericDelegate.self))")
                    return
                }
                XCTAssertEqual(mockNodeActionDelegate.didSelectNodeActionCallCount, 1, "Fail at index: \(index)")
                XCTAssertEqual(audioPlayerViewController.didSelectNodeActionTypeMenuCallCount, 0, "Fail at index: \(index)")
            }
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioPlayerViewRouterNodeActionAdapter,
        audioPlayerViewController: MockAudioPlayerViewController
    ) {
        let audioPlayerViewController = mockAudioPlayerViewController()
        let sut = AudioPlayerViewRouterNodeActionAdapter(
            configEntity: configEntity,
            nodeActionViewControllerDelegate: MockNodeActionViewControllerGenericDelegate(
                viewController: UIViewController(),
                moveToRubbishBinViewModel: MockMoveToRubbishBinViewModel()
            ),
            fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate(link: "any-link", viewController: UIViewController()),
            audioPlayerViewController: audioPlayerViewController
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, audioPlayerViewController)
    }
    
    @MainActor
    private func mockNodeActionViewController() -> NodeActionViewController {
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
    
    private func audioPlayerConfigEntity(
        from originType: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        playerHandler: MockAudioPlayerHandler = MockAudioPlayerHandler()
    ) -> AudioPlayerConfigEntity {
        let node = MockNode(handle: .max)
        
        switch originType {
        case .folderLink:
            return AudioPlayerConfigEntity(node: node, isFolderLink: true, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler)
        case .fileLink:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: fileLink, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler)
        case .chat:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, relatedFiles: relatedFiles, playerHandler: playerHandler)
        case .unknown:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler)
        }
    }
    
    @MainActor
    private func mockAudioPlayerViewController(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MockAudioPlayerViewController {
        let storyboard = UIStoryboard(name: "AudioPlayer", bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: "AudioPlayerViewControllerID") { coder in
            let configEntity = AudioPlayerConfigEntity(
                playerHandler: MockAudioPlayerHandler()
            )
            return MockAudioPlayerViewController(
                coder: coder,
                viewModel: AudioPlayerViewModel(
                    configEntity: configEntity,
                    router: MockAudioPlayerViewRouter(),
                    playbackContinuationUseCase: MockPlaybackContinuationUseCase(),
                    audioPlayerUseCase: MockAudioPlayerUseCase(),
                    accountUseCase: MockAccountUseCase()
                )
            )
        }
        
        guard let audioPlayerViewController = viewController as? MockAudioPlayerViewController else {
            XCTFail("Failed to create \(type(of: AudioPlayerViewController.self)) from storyboard", file: file, line: line)
            fatalError("")
        }
        return audioPlayerViewController
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
