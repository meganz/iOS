@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class CancellableTransferFactoryTests: XCTestCase {
    
    func testMake_fromFolderLink_createsFolderLinkTransferSetup() {
        let node = MockNode(handle: 1)
        let isNodeFromFolderLink = true
        let messageId: HandleEntity = .invalid
        let chatId: HandleEntity = .invalid
        let sut = CancellableTransfer.Factory(node: node, isNodeFromFolderLink: isNodeFromFolderLink, messageId: messageId, chatId: chatId)
        
        let transfer = sut.make()
        
        XCTAssertEqual(transfer.handle, node.handle)
        XCTAssertEqual(transfer.name, nil)
        XCTAssertEqual(transfer.appData, nil)
        XCTAssertEqual(transfer.priority, false)
        XCTAssertEqual(transfer.isFile, node.isFile())
        XCTAssertEqual(transfer.type, .download)
        XCTAssertEqual(transfer.messageId, messageId)
        XCTAssertEqual(transfer.chatId, chatId)
    }
    
    func testMake_fromChat_createsChatDownloadTransferSetup() {
        let node = MockNode(handle: 1)
        let isNodeFromFolderLink = false
        let messageId: HandleEntity = 1
        let chatId: HandleEntity = 2
        let sut = CancellableTransfer.Factory(node: node, isNodeFromFolderLink: isNodeFromFolderLink, messageId: messageId, chatId: chatId)
        
        let transfer = sut.make()
        
        XCTAssertEqual(transfer.handle, node.handle)
        XCTAssertEqual(transfer.name, nil)
        XCTAssertEqual(transfer.appData, nil)
        XCTAssertEqual(transfer.priority, false)
        XCTAssertEqual(transfer.isFile, node.isFile())
        XCTAssertEqual(transfer.type, .downloadChat)
        XCTAssertEqual(transfer.messageId, messageId)
        XCTAssertEqual(transfer.chatId, chatId)
    }
    
    func testMake_notFromFolderLinkNorChat_createsDefaultDownloadTransferSetup() {
        typealias Combination = (chatId: HandleEntity?, messageId: HandleEntity?)
        var combinations = [Combination]()
        combinations.append(contentsOf: [
            Combination(nil, nil),
            Combination(nil, .invalid),
            Combination(.invalid, nil),
            Combination(.invalid, .invalid)
        ])
        
        combinations.enumerated().forEach { (index, combination) in
            let messageId = combination.messageId ?? .invalid
            let chatId = combination.chatId ?? .invalid
            let node = MockNode(handle: 1)
            let isNodeFromFolderLink = false
            let sut = CancellableTransfer.Factory(node: node, isNodeFromFolderLink: isNodeFromFolderLink, messageId: messageId, chatId: chatId)
            
            let transfer = sut.make()
            
            XCTAssertEqual(transfer.handle, node.handle, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.name, nil, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.appData, nil, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.priority, false, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.isFile, node.isFile(), "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.type, .download, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.messageId, .invalid, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(transfer.chatId, .invalid, "failed at index: \(index) on value: \(combination)")
        }
    }
}
