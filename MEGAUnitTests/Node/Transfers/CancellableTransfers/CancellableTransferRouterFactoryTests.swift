@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class CancellableTransferRouterFactoryTests: XCTestCase {

    func testMake_fromFolderLink_createsFolderLinkRouterSetup() {
        let presenter = UIViewController()
        let node = MockNode(handle: 1)
        let isNodeFromFolderLink = true
        let messageId: HandleEntity = .invalid
        let chatId: HandleEntity = .invalid
        let transfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .download)
        let sut = CancellableTransferRouter.Factory(
            presenter: presenter,
            node: node,
            transfers: [transfer],
            isNodeFromFolderLink: isNodeFromFolderLink,
            messageId: messageId,
            chatId: chatId
        )
        
        let router = sut.make()
        
        XCTAssertTrue(router.isFolderLink)
        XCTAssertEqual(router.transferType, .download)
        XCTAssertEqual(router.transfers.count, 1)
        XCTAssertEqual(router.transfers.first?.type, .download)
        XCTAssertEqual(router.transfers.first?.messageId, messageId)
        XCTAssertEqual(router.transfers.first?.chatId, chatId)
        XCTAssertEqual(router.transfers.first?.type, .download)
    }
    
    func testMake_fromChat_createsChatDownloadRouterSetup() {
        let presenter = UIViewController()
        let node = MockNode(handle: 1)
        let isNodeFromFolderLink = false
        let messageId: HandleEntity = 1
        let chatId: HandleEntity = 2
        let transfer = CancellableTransfer(handle: node.handle, messageId: messageId, chatId: chatId, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .downloadChat)
        let sut = CancellableTransferRouter.Factory(
            presenter: presenter,
            node: node,
            transfers: [transfer],
            isNodeFromFolderLink: isNodeFromFolderLink,
            messageId: messageId,
            chatId: chatId
        )
        
        let router = sut.make()
        
        XCTAssertFalse(router.isFolderLink)
        XCTAssertEqual(router.transferType, .downloadChat)
        XCTAssertEqual(router.transfers.count, 1)
        XCTAssertEqual(router.transfers.first?.type, .downloadChat)
        XCTAssertEqual(router.transfers.first?.messageId, messageId)
        XCTAssertEqual(router.transfers.first?.chatId, chatId)
        XCTAssertEqual(router.transfers.first?.type, .downloadChat)
    }
    
    func testMake_notFromFolderLinkNorChat_createsDefaultDownloadRouterSetup() {
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
            let presenter = UIViewController()
            let node = MockNode(handle: 1)
            let isNodeFromFolderLink = false
            let transfer = CancellableTransfer(handle: node.handle, messageId: messageId, chatId: chatId, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .download)
            let sut = CancellableTransferRouter.Factory(
                presenter: presenter,
                node: node,
                transfers: [transfer],
                isNodeFromFolderLink: isNodeFromFolderLink,
                messageId: combination.messageId,
                chatId: combination.chatId
            )
            
            let router = sut.make()
            
            XCTAssertFalse(router.isFolderLink, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(router.transferType, .download, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(router.transfers.count, 1, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(router.transfers.first?.type, .download, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(router.transfers.first?.messageId, .invalid, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(router.transfers.first?.chatId, .invalid, "failed at index: \(index) on value: \(combination)")
            XCTAssertEqual(router.transfers.first?.type, .download, "failed at index: \(index) on value: \(combination)")
        }
    }

}
