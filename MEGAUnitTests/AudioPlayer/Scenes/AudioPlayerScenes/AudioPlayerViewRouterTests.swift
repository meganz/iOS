@testable import MEGA
import MEGADataMock
import MEGADomain
import MEGATest
import XCTest

final class AudioPlayerViewRouterTests: XCTestCase {
    
    func testBuild_whenNodeIsFolderLink_configCorrectDelegate() {
        let sut = makeSUT(nodeOriginType: .folderLink)
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromFolderLink(on: sut)
    }
    
    func testBuild_whenNodeIsFileLink_configCorrectDelegate() {
        let sut = makeSUT(nodeOriginType: .fileLink, fileLink: anyFileLink())
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromFileLink(on: sut)
    }
    
    func testBuild_whenNodeIsFromChat_configCorrectDelegate() {
        let expectedChatId = anyHandleEntity()
        let expectedMessageId = anyHandleEntity()
        let sut = makeSUT(nodeOriginType: .chat, messageId: expectedMessageId, chatId: expectedChatId)
        
        _ = sut.build()
        
        assertThatCorrectDelegateConfiguredWhenNodeIsFromChat(on: sut, expectedChatId, expectedMessageId)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        nodeOriginType originType: AudioPlayerConfigEntity.NodeOriginType,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AudioPlayerViewRouter {
        let currentContextViewController = UIViewController()
        let sut = AudioPlayerViewRouter(
            configEntity: audioPlayerConfigEntity(
                from: originType,
                fileLink: fileLink,
                messageId: messageId,
                chatId: chatId
            ),
            presenter: currentContextViewController
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromFolderLink(on sut: AudioPlayerViewRouter, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertTrue(sut.nodeActionViewControllerDelegate?.isNodeFromFolderLink == true, file: file, line: line)
        XCTAssertNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, .invalid, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, .invalid, file: file, line: line)
    }
    
    private func assertThatCorrectDelegateConfiguredWhenNodeIsFromFileLink(on sut: AudioPlayerViewRouter, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(sut.fileLinkActionViewControllerDelegate, file: file, line: line)
        XCTAssertNil(sut.nodeActionViewControllerDelegate, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.messageId, nil, file: file, line: line)
        XCTAssertEqual(sut.nodeActionViewControllerDelegate?.chatId, nil, file: file, line: line)
    }
    
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
        chatId: HandleEntity? = nil
    ) -> AudioPlayerConfigEntity {
        let node = MockNode(handle: .max)
        let playerHandler = MockAudioPlayerHandler()
        
        switch originType {
        case .folderLink:
            return AudioPlayerConfigEntity(node: node, isFolderLink: true, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: nil, playerHandler: playerHandler)
        case .fileLink:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: fileLink, messageId: .invalid, chatId: .invalid, relatedFiles: nil, playerHandler: playerHandler)
        case .chat:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, relatedFiles: nil, playerHandler: playerHandler)
        case .unknown:
            return AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, messageId: .invalid, chatId: .invalid, relatedFiles: nil, playerHandler: playerHandler)
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
    
}
