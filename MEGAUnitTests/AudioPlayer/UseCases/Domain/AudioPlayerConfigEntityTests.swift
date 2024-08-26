@testable import MEGA
import MEGADomain
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerConfigEntityTests: XCTestCase {
    
    // MARK: - isFolderLink
    
    func testIsFolderLink_WhenIsFolderLink_ReturnsTrue() {
        let sut = makeSUT(isFolderLink: true)
        
        let result = sut.isFolderLink
        
        XCTAssertTrue(result)
    }
    
    func testIsFolderLink_WhenIsNotFolderLink_ReturnsFalse() {
        let sut = makeSUT(isFolderLink: false)
        
        let result = sut.isFolderLink
        
        XCTAssertFalse(result)
    }
    
    // MARK: - node
    
    func testNode_WhenNodeIsSet_ReturnsCorrectNode() {
        let node = MockNode(handle: 1)
        let sut = makeSUT(node: node)
        
        let result = sut.node
        
        XCTAssertEqual(result, node)
    }
    
    func testNode_WhenNodeIsNotSet_ReturnsNil() {
        let sut = makeSUT()
        
        let result = sut.node
        
        XCTAssertNil(result)
    }
    
    // MARK: - chatId
    
    func testChatId_WhenChatIdIsSet_ReturnsCorrectChatId() {
        let chatId: HandleEntity = 123
        let sut = makeSUT(chatId: chatId)
        
        let result = sut.chatId
        
        XCTAssertEqual(result, chatId)
    }
    
    func testChatId_WhenChatIdIsNotSet_ReturnsNil() {
        let sut = makeSUT()
        
        let result = sut.chatId
        
        XCTAssertNil(result)
    }
    
    // MARK: - isFileLink
    
    func testIsFileLink_WhenFileLinkExists_ReturnsTrue() {
        let sut = makeSUT(fileLink: "exampleFileLink")
        
        let result = sut.isFileLink
        
        XCTAssertTrue(result)
    }
    
    func testIsFileLink_WhenRelatedFilesExist_ReturnsFalse() {
        let sut = makeSUT(relatedFiles: ["relatedFile1.mp3", "relatedFile2.mp3"])
        
        let result = sut.isFileLink
        
        XCTAssertFalse(result)
    }
    
    // MARK: - playerType
    
    func testPlayerType_WhenIsFolderLink_ReturnsFolderLink() {
        let sut = makeSUT(isFolderLink: true)
        
        let result = sut.playerType
        
        XCTAssertEqual(result, .folderLink)
    }
    
    func testPlayerType_WhenIsFileLink_ReturnsFileLink() {
        let sut = makeSUT(fileLink: "exampleFileLink")
        
        let result = sut.playerType
        
        XCTAssertEqual(result, .fileLink)
    }
    
    func testPlayerType_WhenRelatedFilesExist_ReturnsOffline() {
        let sut = makeSUT(relatedFiles: ["relatedFile1.mp3", "relatedFile2.mp3"])
        
        let result = sut.playerType
        
        XCTAssertEqual(result, .offline)
    }
    
    func testPlayerType_WhenDefaultCase_ReturnsDefault() {
        let sut = makeSUT()
        
        let result = sut.playerType
        
        XCTAssertEqual(result, .default)
    }
    
    // MARK: - nodeOriginType
    
    func testNodeOriginType_WhenIsFolderLink_ReturnsFolderLink() {
        let sut = makeSUT(isFolderLink: true)
        
        let result = sut.nodeOriginType
        
        XCTAssertEqual(result, .folderLink)
    }
    
    func testNodeOriginType_WhenIsFileLink_ReturnsFileLink() {
        let sut = makeSUT(fileLink: "exampleFileLink")
        
        let result = sut.nodeOriginType
        
        XCTAssertEqual(result, .fileLink)
    }
    
    func testNodeOriginType_WhenChatIdsExist_ReturnsChat() {
        let sut = makeSUT(messageId: 1, chatId: 2)
        
        let result = sut.nodeOriginType
        
        XCTAssertEqual(result, .chat)
    }
    
    // MARK: - relatedFiles
    
    func testRelatedFiles_whenRelatedFilesIsAudioFiles_doesNotFilterRelatedFiles() {
        let expectedRelatedFiles = ["relatedFile1.mp3", "relatedFile2.mp3"]
        let sut = makeSUT(relatedFiles: expectedRelatedFiles)
        
        let result = sut.relatedFiles
        
        XCTAssertEqual(result, expectedRelatedFiles)
    }
    
    func testRelatedFiles_whenRelatedFilesNonAudioFiles_filterRelatedFiles() {
        let expectedRelatedFiles = ["relatedFile1.mov", "relatedFile2.mov", "relatedFile3.jpeg", "relatedFile4.txt"]
        let sut = makeSUT(relatedFiles: expectedRelatedFiles)
        
        let result = sut.relatedFiles
        
        XCTAssertEqual(result?.isEmpty, true)
    }
    
    func testRelatedFiles_whenRelatedFilesMixAudioAndNonAudio_filterRelatedFiles() {
        let expectedRelatedFiles = ["relatedFile1.mp3", "relatedFile2.mov", "relatedFile3.jpeg", "relatedFile4.txt"]
        let sut = makeSUT(relatedFiles: expectedRelatedFiles)
        
        let result = sut.relatedFiles
        
        XCTAssertEqual(result, [ expectedRelatedFiles[0] ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        node: MockNode? = nil,
        isFolderLink: Bool = false,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        parentNode: MockNode? = nil,
        allNodes: [MockNode]? = nil,
        shouldResetPlayer: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AudioPlayerConfigEntity {
        let playerHandler = MockAudioPlayerHandler()
        let sut = AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: relatedFiles,
            parentNode: parentNode,
            allNodes: allNodes,
            playerHandler: playerHandler,
            shouldResetPlayer: shouldResetPlayer
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: playerHandler, file: file, line: line)
        return sut
    }
}
