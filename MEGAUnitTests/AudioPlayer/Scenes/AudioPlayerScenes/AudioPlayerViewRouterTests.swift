@testable import MEGA
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

@MainActor
@Suite("AudioPlayerViewRouter")
struct AudioPlayerViewRouterTests {
    private func anyFileLink() -> String { "https://some-file-link.com" }
    private func anyHandle() -> HandleEntity { .max }
    
    @Test("build – folder link configures node delegate")
    func buildFolderLinkConfiguresNodeDelegate() {
        let (sut, _) = makeSUT(origin: .folderLink)
        
        _ = sut.build()
        
        assertNodeDelegate(
            in: sut,
            isFromFolderLink: true,
            messageId: .invalid,
            chatId: .invalid
        )
        #expect(sut.fileLinkActionViewControllerDelegate == nil)
    }
    
    @Test("build – file link configures file link delegate")
    func buildFileLinkConfiguresFileLinkDelegate() {
        let (sut, _) = makeSUT(origin: .fileLink, fileLink: anyFileLink())
        
        _ = sut.build()
        
        #expect(sut.fileLinkActionViewControllerDelegate != nil)
        #expect(sut.nodeActionViewControllerDelegate == nil)
    }
    
    @Test("build – chat configures node delegate with ids")
    func buildChatConfiguresNodeDelegateWithIds() {
        let expectedChatId = anyHandle()
        let expectedMessageId = anyHandle()
        let (sut, _) = makeSUT(
            origin: .chat,
            messageId: expectedMessageId,
            chatId: expectedChatId
        )
        
        _ = sut.build()
        
        assertNodeDelegate(
            in: sut,
            isFromFolderLink: false,
            messageId: expectedMessageId,
            chatId: expectedChatId
        )
        #expect(sut.fileLinkActionViewControllerDelegate == nil)
    }
    
    @Test("start – presents built view")
    func startPresentsBuiltView() {
        let (sut, presenter) = makeSUT()
        
        sut.start()
        
        #expect(presenter.presentCallCount == 1)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(
        origin: AudioPlayerConfigEntity.NodeOriginType = .folderLink,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewRouter, presenter: MockViewController) {
        let presenter = MockViewController()
        let config = makeConfig(
            origin: origin,
            fileLink: fileLink,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: relatedFiles
        )
        let sut = AudioPlayerViewRouter(
            configEntity: config,
            presenter: presenter,
            tracker: MockTracker()
        )
        return (sut, presenter)
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
        case .folderLink: .init(
            node: node,
            isFolderLink: true,
            fileLink: nil,
            messageId: .invalid,
            chatId: .invalid,
            relatedFiles: relatedFiles
        )
        case .fileLink: .init(
            node: node,
            isFolderLink: false,
            fileLink: fileLink,
            messageId: .invalid,
            chatId: .invalid,
            relatedFiles: relatedFiles
        )
        case .chat: .init(
            node: node,
            isFolderLink: false,
            fileLink: nil,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: relatedFiles
        )
        case .unknown: .init(
            node: node,
            isFolderLink: false,
            fileLink: nil,
            messageId: .invalid,
            chatId: .invalid,
            relatedFiles: relatedFiles
        )
        }
    }
    
    private func assertNodeDelegate(
        in sut: AudioPlayerViewRouter,
        isFromFolderLink: Bool,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) {
        guard let delegate = sut.nodeActionViewControllerDelegate else {
            Issue.record("Expected nodeActionViewControllerDelegate to be non-nil")
            return
        }
        
        #expect(delegate.isNodeFromFolderLink == isFromFolderLink)
        #expect(delegate.messageId == messageId)
        #expect(delegate.chatId == chatId)
    }
}

private final class MockViewController: UIViewController {
    private(set) var presentCallCount = 0
    private(set) var dismissCallCount = 0
    
    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentCallCount += 1
    }
    
    override func dismiss(
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        dismissCallCount += 1
    }
}
