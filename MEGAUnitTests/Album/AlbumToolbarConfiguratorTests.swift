import XCTest
@testable import MEGA

class AlbumToolbarConfiguratorTest: XCTestCase {
    func testToolbarItems_forGifAndRawAlbum_shouldReturnCorrectItems() {
        [AlbumType.gif, .raw].forEach {
            let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                               shareLinkAction: { _ in },
                                               moveAction: { _ in },
                                               copyAction: { _ in },
                                               deleteAction: { _ in },
                                               favouriteAction: { _ in },
                                               removeToRubbishBinAction: { _ in },
                                               exportAction: { _ in },
                                               sendToChatAction: { _ in },
                                               moreAction: { _ in },
                                               albumType: $0)
            let buttonItems = sut.toolbarItems(forNodes: nil)
            XCTAssertEqual(buttonItems, [
                sut.downloadItem,
                sut.flexibleItem,
                sut.shareLinkItem,
                sut.flexibleItem,
                sut.exportItem,
                sut.flexibleItem,
                sut.sendToChatItem
            ])
        }
    }
    
    func testToolbarItems_forFavouriteAlbum_shouldReturnCorrectItems() {
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                           shareLinkAction: { _ in },
                                           moveAction: { _ in },
                                           copyAction: { _ in },
                                           deleteAction: { _ in },
                                           favouriteAction: { _ in },
                                           removeToRubbishBinAction: { _ in },
                                           exportAction: { _ in },
                                           sendToChatAction: { _ in },
                                           moreAction: { _ in },
                                           albumType: .favourite)
        let buttonItems = sut.toolbarItems(forNodes: nil)
        XCTAssertEqual(buttonItems, [
            sut.downloadItem,
            sut.flexibleItem,
            sut.shareLinkItem,
            sut.flexibleItem,
            sut.exportItem,
            sut.flexibleItem,
            sut.sendToChatItem,
            sut.flexibleItem,
            sut.favouriteItem
        ])
    }
    
    func testToolbarItems_forUserAlbum_shouldReturnCorrectItems() {
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in },
                                           shareLinkAction: { _ in },
                                           moveAction: { _ in },
                                           copyAction: { _ in },
                                           deleteAction: { _ in },
                                           favouriteAction: { _ in },
                                           removeToRubbishBinAction: { _ in },
                                           exportAction: { _ in },
                                           sendToChatAction: { _ in },
                                           moreAction: { _ in },
                                           albumType: .user)
        let buttonItems = sut.toolbarItems(forNodes: nil)
        XCTAssertEqual(buttonItems, [
            sut.downloadItem,
            sut.flexibleItem,
            sut.shareLinkItem,
            sut.flexibleItem,
            sut.exportItem,
            sut.flexibleItem,
            sut.sendToChatItem,
            sut.flexibleItem,
            sut.removeToRubbishBinItem
        ])
    }
    
    func testSentToChatButton_onButtonPress_shouldFireSendToChatAction() {
        let exp = expectation(description: "should fire send to chat action")
        let sut = AlbumToolbarConfigurator(downloadAction: { _ in XCTFail("Unexpected action") },
                                           shareLinkAction: { _ in XCTFail("Unexpected action") },
                                           moveAction: { _ in XCTFail("Unexpected action") },
                                           copyAction: { _ in XCTFail("Unexpected action") },
                                           deleteAction: { _ in XCTFail("Unexpected action") },
                                           favouriteAction: { _ in XCTFail("Unexpected action") },
                                           removeToRubbishBinAction: { _ in XCTFail("Unexpected action") },
                                           exportAction: { _ in XCTFail("Unexpected action") },
                                           sendToChatAction: { _ in exp.fulfill() },
                                           moreAction: { _ in XCTFail("Unexpected action") },
                                           albumType: .user)
        sut.buttonPressed(sut.sendToChatItem)
        wait(for: [exp], timeout: 1.0)
    }
}
