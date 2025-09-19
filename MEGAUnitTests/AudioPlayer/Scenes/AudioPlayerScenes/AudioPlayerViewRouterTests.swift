@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGATest
import XCTest

@MainActor
final class AudioPlayerViewRouterTests: XCTestCase {
    
    // MARK: - Tests
    
    func testBuild_whenFolderLink_configuresNodeDelegate() {
        let (sut, _) = makeSUT(nodeOriginType: .folderLink)
        
        _ = sut.build()
        
        assertNodeDelegate(
            in: sut,
            isFromFolderLink: true,
            messageId: .invalid,
            chatId: .invalid
        )
        assertFileLinkDelegateIsNil(in: sut)
    }
    
    func testBuild_whenFileLink_configuresFileLinkDelegate() {
        let (sut, _) = makeSUT(
            nodeOriginType: .fileLink,
            fileLink: anyFileLink()
        )
        
        _ = sut.build()
        
        assertFileLinkDelegateIsNotNil(in: sut)
        assertNodeDelegateIsNil(in: sut)
    }
    
    func testBuild_whenFromChat_configuresNodeDelegateWithIds() {
        let expectedChatId = anyHandleEntity()
        let expectedMessageId = anyHandleEntity()
        let (sut, _) = makeSUT(
            nodeOriginType: .chat,
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
        assertFileLinkDelegateIsNil(in: sut)
    }
    
    func testStart_presentsBuiltView() {
        let (sut, presenter) = makeSUT()
        
        sut.start()
        
        XCTAssertEqual(presenter.presentCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        nodeOriginType originType: AudioPlayerConfigEntity.NodeOriginType = .folderLink,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewRouter, presenter: MockViewController) {
        let presenter = MockViewController()
        let config = audioPlayerConfigEntity(
            from: originType,
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
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: presenter, file: file, line: line)
        return (sut, presenter)
    }
    
    private func audioPlayerConfigEntity(
        from originType: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil
    ) -> AudioPlayerConfigEntity {
        let node = MockNode(handle: .max)
        switch originType {
        case .folderLink:
            return .init(
                node: node,
                isFolderLink: true,
                fileLink: nil,
                messageId: .invalid,
                chatId: .invalid,
                relatedFiles: relatedFiles
            )
        case .fileLink:
            return .init(
                node: node,
                isFolderLink: false,
                fileLink: fileLink,
                messageId: .invalid,
                chatId: .invalid,
                relatedFiles: relatedFiles
            )
        case .chat:
            return .init(
                node: node,
                isFolderLink: false,
                fileLink: nil,
                messageId: messageId,
                chatId: chatId,
                relatedFiles: relatedFiles
            )
        case .unknown:
            return .init(
                node: node,
                isFolderLink: false,
                fileLink: nil,
                messageId: .invalid,
                chatId: .invalid,
                relatedFiles: relatedFiles
            )
        }
    }
    // MARK: - Delegate assertions
    
    private func assertNodeDelegate(
        in sut: AudioPlayerViewRouter,
        isFromFolderLink: Bool,
        messageId: HandleEntity,
        chatId: HandleEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let delegate = try? XCTUnwrap(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(delegate?.isNodeFromFolderLink, isFromFolderLink, file: file, line: line)
        XCTAssertEqual(delegate?.messageId, messageId, file: file, line: line)
        XCTAssertEqual(delegate?.chatId, chatId, file: file, line: line)
    }
    
    private func assertNodeDelegateIsNil(
        in sut: AudioPlayerViewRouter,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
    }
    
    private func assertFileLinkDelegateIsNotNil(
        in sut: AudioPlayerViewRouter,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
    }
    
    private func assertFileLinkDelegateIsNil(
        in sut: AudioPlayerViewRouter,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
    }
    
    // MARK: - Test fixtures
    
    private func anyFileLink() -> String {
        "https://some-file-link.com"
    }
    
    private func anyHandleEntity() -> HandleEntity {
        .max
    }
}

private final class MockViewController: UIViewController {
    private(set) var presentCallCount = 0
    private(set) var dismissCallCount = 0
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCallCount += 1
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCallCount += 1
    }
}
