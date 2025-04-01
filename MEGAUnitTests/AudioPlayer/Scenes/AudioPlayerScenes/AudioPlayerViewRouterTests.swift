@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerViewRouterTests: XCTestCase {
    
    @MainActor
    func testBuild_whenNodeIsFolderLink_configCorrectDelegate() {
        let audioPlayerViewController = MockViewController()
        let (sut, _, _, _, _, _, _) = makeSUT(nodeOriginType: .folderLink, audioPlayerViewController: audioPlayerViewController)
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromFolderLink(on: sut)
    }
    
    @MainActor
    func testBuild_whenNodeIsFileLink_configCorrectDelegate() {
        let audioPlayerViewController = MockViewController()
        
        let (sut, _, _, _, _, _, _) = makeSUT(
            nodeOriginType: .fileLink,
            fileLink: anyFileLink(),
            audioPlayerViewController: audioPlayerViewController
        )
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromFileLink(on: sut)
    }
    
    @MainActor
    func testBuild_whenNodeIsFromChat_configCorrectDelegate() {
        let audioPlayerViewController = MockViewController()
        let expectedChatId = anyHandleEntity()
        let expectedMessageId = anyHandleEntity()
        let (sut, _, _, _, _, _, _) = makeSUT(
            nodeOriginType: .chat,
            messageId: expectedMessageId,
            chatId: expectedChatId,
            audioPlayerViewController: audioPlayerViewController
        )
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromChat(on: sut, expectedChatId, expectedMessageId)
    }
    
    @MainActor
    func testStart_presentBuildedView() {
        let (sut, presenter, _, _, _, _, _) = makeSUT()
        
        sut.start()
        
        XCTAssertEqual(presenter.presentCallCount, 1)
    }
    
    @MainActor func testShowMiniPlayer_withNode_showsMiniPlayer() {
        let (sut, _, _, mockPlayerHandler, _, _, _) = makeSUT()
        sut.start()
        
        sut.showMiniPlayer(node: MockNode(handle: 1), shouldReload: false)
        
        XCTAssertEqual(mockPlayerHandler.initMiniPlayerCallCount, 1)
    }
    
    @MainActor func testShowMiniPlayer_withouthNode_showsMiniPlayer() {
        let (sut, _, _, mockPlayerHandler, _, _, _) = makeSUT()
        sut.start()
        
        sut.showMiniPlayer(node: nil, shouldReload: false)
        
        XCTAssertEqual(mockPlayerHandler.initMiniPlayerCallCount, 1)
    }
    
    @MainActor func testShowMiniPlayer_withFile_showsMiniPlayer() {
        let (sut, _, _, mockPlayerHandler, _, _, _) = makeSUT()
        sut.start()
        
        sut.showMiniPlayer(file: "any-file", shouldReload: false)
        
        XCTAssertEqual(mockPlayerHandler.initMiniPlayerCallCount, 1)
    }
    
    @MainActor func testGoToPlaylist_whenCalled_startsPlaylistRouter() {
        let (sut, _, _, _, audioPlaylistViewRouter, _, _) = makeSUT()
        
        sut.goToPlaylist()
        
        XCTAssertEqual(audioPlaylistViewRouter.start_calledTimes, 1)
    }
    
    @MainActor func testDismiss_whenCalled_dismissView() {
        let (sut, _, _, _, _, audioPlayerViewController, _) = makeSUT(audioPlayerViewController: MockViewController())
        
        sut.dismiss()
        
        XCTAssertEqual(audioPlayerViewController.dismissCallCount, 1)
    }
    
    @MainActor func testShowAction_whenCalled_presentNodeActionView() {
        let (sut, _, _, _, _, audioPlayerViewController, _) = makeSUT(audioPlayerViewController: MockViewController())
        
        sut.showAction(for: MockNode(handle: 1), sender: "any-sender")
        
        XCTAssertEqual(audioPlayerViewController.presentCallCount, 1)
    }
    
    @MainActor func testHideActionSelected_shouldTrackEvent() {
        let audioPlayerViewController = MockViewController()
        let (sut, _, _, _, _, _, tracker) = makeSUT(audioPlayerViewController: audioPlayerViewController)
        
        _ = sut.build()
        
        sut.nodeActionViewControllerDelegate?.nodeAction(mockNodeActionViewController(), didSelect: .hide, for: MEGANode(), from: UIButton())
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [AudioPlayerHideNodeMenuItemEvent()])
    }
    
    // MARK: - Helpers
    
    @MainActor private func makeSUT(
        nodeOriginType originType: AudioPlayerConfigEntity.NodeOriginType = .folderLink,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        audioPlayerViewController: MockViewController? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewRouter, presenter: MockViewController, configEntity: AudioPlayerConfigEntity, mockPlayerHandler: MockAudioPlayerHandler, audioPlaylistViewRouter: MockAudioPlaylistViewRouter, baseViewController: MockViewController, tracker: MockTracker) {
        let audioPlayerViewController = audioPlayerViewController ?? MockViewController()
        let currentContextViewController = MockViewController()
        let audioPlaylistViewRouter = MockAudioPlaylistViewRouter()
        let tracker = MockTracker()
        let (configEntity, mockPlayerHandler) = audioPlayerConfigEntity(
            from: originType,
            fileLink: fileLink,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: relatedFiles
        )
        let sut = AudioPlayerViewRouter(
            configEntity: configEntity,
            presenter: currentContextViewController,
            audioPlaylistViewRouter: audioPlaylistViewRouter,
            tracker: tracker
        )
        sut.baseViewController = audioPlayerViewController
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, currentContextViewController, configEntity, mockPlayerHandler, audioPlaylistViewRouter, audioPlayerViewController, tracker)
    }
    
    @MainActor
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromFolderLink(on sut: AudioPlayerViewRouter, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertTrue(sut.nodeActionViewControllerDelegate?.isNodeFromFolderLink == true, file: file, line: line)
        XCTAssertNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, .invalid, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, .invalid, file: file, line: line)
    }
    
    @MainActor
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromFileLink(on sut: AudioPlayerViewRouter, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
        XCTAssertNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, nil, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, nil, file: file, line: line)
    }
    
    @MainActor
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromChat(on sut: AudioPlayerViewRouter, _ expectedMessageId: HandleEntity, _ expectedChatId: HandleEntity, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, expectedMessageId, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, expectedChatId, file: file, line: line)
        XCTAssertTrue(sut.nodeActionViewControllerDelegate?.isNodeFromFolderLink == false, file: file, line: line)
        XCTAssertNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
    }
    
    private func audioPlayerConfigEntity(
        from originType: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        playerHandler: MockAudioPlayerHandler = MockAudioPlayerHandler()
    ) -> (configEntity: AudioPlayerConfigEntity, playerHandler: MockAudioPlayerHandler) {
        let node = MockNode(handle: .max)
        
        switch originType {
        case .folderLink:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: true, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        case .fileLink:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: fileLink, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        case .chat:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        case .unknown:
            return (AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: relatedFiles, playerHandler: playerHandler), playerHandler)
        }
    }
    
    private func anyFileLink() -> String {
        anyURL().absoluteString
    }
    
    private func anyURL() -> URL {
        URL(string: "https://some-file-link.com")!
    }
    
    private func anyHandleEntity() -> HandleEntity {
        .max
    }
    
    @MainActor
    private func mockNodeActionViewController() -> NodeActionViewController {
        NodeActionViewController(
            node: MockNode(handle: 1),
            delegate: NodeActionViewControllerGenericDelegate(
                viewController: UIViewController(),
                moveToRubbishBinViewModel: MockMoveToRubbishBinViewModel()
            ),
            displayMode: .albumLink,
            isInVersionsView: false,
            isBackupNode: false,
            sender: "any-sender"
        )
    }
}

private class MockViewController: UIViewController {
    private(set) var presentCallCount = 0
    private(set) var dismissCallCount = 0
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCallCount += 1
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCallCount += 1
    }
}
